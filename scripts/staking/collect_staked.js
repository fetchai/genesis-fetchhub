const Web3 = require("web3");
const fs = require("fs");
const { BN } = require("bn.js");
const { Decimal } = require("decimal.js");
const path = require("path");
const EthUtil = require("ethereumjs-util");
const EthTx = require("@ethereumjs/tx");
const { bech32 } = require("bech32");
const { createHash } = require("crypto");
const secp256k1 = require("secp256k1");
const assert = require("assert");

const decimalPrecision = 100;
const fetErc20CanonicalMultiplier = new Decimal("1e18");

function canonicalFetToFet(canonicalVal) {
    const origPrecision = Decimal.precision;
    Decimal.set({ precision: decimalPrecision });
    try {
        return new Decimal(canonicalVal.toString()).div(
            fetErc20CanonicalMultiplier
        );
    } finally {
        Decimal.set({ precision: origPrecision });
    }
}

function fetToCanonicalFet(val) {
    const origPrecision = Decimal.precision;
    Decimal.set({ precision: decimalPrecision });
    try {
        return new Decimal(val.toString()).mul(fetErc20CanonicalMultiplier);
    } finally {
        Decimal.set({ precision: origPrecision });
    }
}

const dir = __dirname;
const infuraProjectId = fs.readFileSync(".infura_project_id").toString().trim();
const _endpoint = "wss://mainnet.infura.io/ws/v3";
const endpoint = `${_endpoint}/${infuraProjectId}`;

const web3http = new Web3(`https://mainnet.infura.io/v3/${infuraProjectId}`);

const web3 = new Web3(
    new Web3.providers.WebsocketProvider(endpoint, {
        clientConfig: {
            maxReceivedFrameSize: 10000000000,
            maxReceivedMessageSize: 10000000000,
        },
    })
);

class Contract {
    constructor(filename, address, startBlock = null, endBlock = null) {
        const abi = require(path.join(dir, filename)).abi;
        this.startBlock = startBlock;
        this.endBlock = endBlock;
        this.contract = new web3.eth.Contract(abi, address);
    }
}

class Asset {
    constructor(principal, compountInterest) {
        this.principal = new BN(principal); // necessary to avoid returning original `value` BN instance
        this.compoundInterest = new BN(compountInterest); // necessary to avoid returning original `value` BN instance

        this.principalFET = canonicalFetToFet(this.principal);
        this.compoundInterestFET = canonicalFetToFet(this.compoundInterest);
        this.compositeFET = this.principalFET.add(this.compoundInterestFET);
    }

    clone() {
        return new Asset(this.principal, this.compoundInterest);
    }
}

class InterestRate {
    constructor(sinceBlock, ratePerBlockCanonical) {
        this.sinceBlock = new BN(sinceBlock); // necessary to avoid returning original `value` BN instance
        this.ratePerBlockCanonical = new BN(ratePerBlockCanonical);
        this.ratePerBlock = canonicalFetToFet(
            this.ratePerBlockCanonical.toString()
        );
    }

    clone() {
        return new InterestRate(this.sinceBlock, this.ratePerBlockCanonical);
    }
}

class InterestRates {
    constructor(startIdx, nextIdx, ratesMap) {
        this.startIdx = parseInt(startIdx); // necessary to avoid returning original `value` BN instance
        this.nextIdx = parseInt(nextIdx);
        this.ratesMap = {};
        for (const [idx, rate] of Object.entries(ratesMap)) {
            this.ratesMap[idx] = rate.clone();
        }
    }

    static async queryFromContract() {
        const startIdx = parseInt(
            await staking.contract.methods._interestRatesStartIdx().call()
        );
        const nextIdx = parseInt(
            await staking.contract.methods._interestRatesNextIdx().call()
        );

        let rates = {};
        for (let i = startIdx; i < nextIdx; ++i) {
            const r = await staking.contract.methods._interestRates(i).call();
            rates[i] = new InterestRate(r[0], r[1]);
        }

        return new InterestRates(startIdx, nextIdx, rates);
    }

    clone() {
        return new InterestRates(this.startIdx, this.nextIdx, this.ratesMap);
    }
}

class Stake {
    constructor(asset, sinceBlock, sinceInterestRateIndex) {
        this.asset = asset.clone(); // necessary to avoid returning original `value` BN instance
        this.sinceBlock = new BN(sinceBlock); // necessary to avoid returning original `value` BN instance
        this.sinceInterestRateIndex = new BN(sinceInterestRateIndex);
    }

    static async queryFromContract(userAddress) {
        const s = await staking.contract.methods
            .getStakeForUser(userAddress)
            .call();

        const asset = new Asset(s[0], s[1]);
        return new Stake(asset, s[2], s[3]);
    }

    calcCompoundInterest(interestRates, untilBlock_) {
        const untilBlock = new BN(untilBlock_);

        let composite = new Decimal(this.asset.compositeFET);
        const _1 = new Decimal("1");

        for (
            let i = parseInt(this.sinceInterestRateIndex);
            i < interestRates.nextIdx;
            ++i
        ) {
            const n = i + 1;
            const rate = interestRates.ratesMap[i];
            let startBlock = BN.max(this.sinceBlock, rate.sinceBlock);
            let endBlock = untilBlock;

            if (n < interestRates.nextIdx) {
                const nextRate = interestRates.ratesMap[n];
                endBlock = BN.min(endBlock, nextRate.sinceBlock);
            }

            const num_of_blocks = new Decimal(
                endBlock.sub(startBlock).toString()
            );
            const interestMultiplier = _1
                .add(rate.ratePerBlock)
                .pow(num_of_blocks);
            const accrued_composite = composite.mul(interestMultiplier);
            composite = accrued_composite;
        }

        const compoundInterest = composite.sub(this.asset.principalFET);

        return compoundInterest;
    }

    clone() {
        return new Stake(
            this.asset,
            this.sinceBlock,
            this.sinceInterestRateIndex
        );
    }
}

class UserAssets {
    constructor(stake, lockedAggr, liquidity) {
        this.stake = stake.clone(); // necessary to avoid returning original `value` BN instance
        this.lockedAggr = lockedAggr.clone();
        this.liquidity = liquidity.clone(); // necessary to avoid returning original `value` BN instance
    }

    static async queryFromContract(userAddress) {
        const stake = await Stake.queryFromContract(userAddress);

        const locA = await staking.contract.methods
            .getLockedAssetsAggregateForUser(userAddress)
            .call();
        const lockedAggr = new Asset(locA[0], locA[1]);

        const liq = await staking.contract.methods
            ._liquidity(userAddress)
            .call();
        const liquidity = new Asset(liq[0], liq[1]);

        return new UserAssets(stake, lockedAggr, liquidity);
    }

    calcCompoundInterest(interestRates, untilBlock) {
        const compoundInterest_from_stake = this.stake.calcCompoundInterest(
            interestRates,
            untilBlock
        );
        return [
            compoundInterest_from_stake
                .add(this.lockedAggr.compoundInterestFET)
                .add(this.liquidity.compoundInterestFET),
            compoundInterest_from_stake,
        ];
    }

    calcPrincipal() {
        return [
            this.stake.asset.principalFET
                .add(this.lockedAggr.principalFET)
                .add(this.liquidity.principalFET),
            this.stake.asset.principalFET,
        ];
    }

    clone() {
        return new UserAssets(this.stake, this.lockedAggr, this.liquidity);
    }
}

class User {
    constructor(address, pubkey) {
        const addrFromPubkey = EthUtil.pubToAddress(
            EthUtil.toBuffer(EthUtil.addHexPrefix(pubkey))
        );
        assert(
            addrFromPubkey.equals(EthUtil.toBuffer(address)),
            `pubkey ${pubkey} does not match address, got ${addrFromPubkey.toString(
                "hex"
            )}, want ${address}.`
        );

        this.address = address;
        this.pubkey = pubkey;
        this.fetchAddr = secp256k1UncompressedPubkeyToFetchAddress(this.pubkey);
        this.events = [];
        this.assets = null;
        this.principalFET_whole = null;
        this.principalFET_staked = null;
        this.compoundInterestFET_whole = null;
        this.compoundInterestFET_staked = null;
    }

    async init(interestRates, untilBlock) {
        this.assets = await UserAssets.queryFromContract(this.address);
        [this.principalFET_whole, this.principalFET_staked] =
            this.assets.calcPrincipal();
        [this.compoundInterestFET_whole, this.compoundInterestFET_staked] =
            this.assets.calcCompoundInterest(interestRates, untilBlock);
    }
}

async function getPublicKeyFromTxHash(txHash) {
    const tx = await web3http.eth.getTransaction(txHash);
    const txDetails = {
        chainId: tx.chainId,
        accessList: tx.accessList,
        nonce: tx.nonce,
        maxPriorityFeePerGas: tx.maxPriorityFeePerGas,
        maxFeePerGas: tx.maxFeePerGas,
        gasLimit: tx.gas,
        gasPrice: EthUtil.bufferToHex(new EthUtil.BN(tx.gasPrice)),
        to: tx.to,
        value: EthUtil.bufferToHex(new EthUtil.BN(tx.value)),
        data: tx.input,
        v: tx.v,
        r: tx.r,
        s: tx.s,
        type: tx.type,
    };
    const txObj = EthTx.TransactionFactory.fromTxData(txDetails);
    return txObj.getSenderPublicKey().toString("hex");
}

function secp256k1UncompressedPubkeyToFetchAddress(pubKeyHexStr) {
    const binaryAddress = createHash("ripemd160")
        .update(
            createHash("sha256")
                .update(
                    secp256k1.publicKeyConvert(
                        Buffer.from("04" + pubKeyHexStr, "hex"),
                        true
                    )
                )
                .digest()
        )
        .digest();

    return bech32.encode("fetch", bech32.toWords(binaryAddress));
}

const staking = new Contract(
    "Staking.json",
    "0x351baC612B50e87B46e4b10A282f632D41397DE2",
    11061460,
    "latest"
);

async function main() {
    try {
        //const current_block = await web3.eth.getBlockNumber();

        //const curr_time = new Date();
        //const end_time = new Date("2021-09-15T14:00:00Z");
        //if (end_time < curr_time) {
        //    console.error(
        //        `Current time ${curr_time} passed expected decommission time ${end_time} for FET Staking contract.`
        //    );
        //}
        //const average_block_generation_time_secs = 13.17; // [sec/block]
        //const end_block = Math.ceil(
        //    current_block +
        //        (end_time - curr_time) /
        //            (average_block_generation_time_secs * 1000)
        //);

        /* End block hight carved in the stone */
        const end_block = 13224000;

        const interestRates = await InterestRates.queryFromContract();

        const retval = new Object();
        retval.staking = {};
        retval.staking.events_list = [];
        retval.staking.users = {};

        const staking_event_names = ["LiquidityDeposited"];
        for (let i = 0; i < staking_event_names.length; ++i) {
            const evt_name = staking_event_names[i];
            events = await staking.contract.getPastEvents(evt_name, {
                fromBlock: staking.startBlock,
                toBlock: staking.endBlock,
            });
            retval.staking.events_list =
                retval.staking.events_list.concat(events);
            const users_dict = retval.staking.users;

            for (let i = 0; i < events.length; ++i) {
                const e = events[i];
                if (e.removed) {
                    continue;
                }

                let user;
                const userAddr = e.returnValues.stakerAddress;
                if (e.returnValues.stakerAddress in users_dict) {
                    user = users_dict[userAddr];
                } else {
                    userPubkey = await getPublicKeyFromTxHash(
                        e.transactionHash
                    );
                    user = new User(userAddr, userPubkey);
                    users_dict[userAddr] = user;
                }

                user.events.push(e);
            }
        }

        //console.log(`USER ADDRESS, USER PUBKEY, USER FETCH ADDRESS, TOTAL[afet], PRINCIPAL WHOLE[afet], COMPOUND INTEREST(LIQUID + LOCKED + STAKED)[afet]`);
        for (const [key, user] of Object.entries(retval.staking.users)) {
            await user.init(interestRates, end_block);

            const principal = fetToCanonicalFet(user.principalFET_whole);
            const compound = fetToCanonicalFet(user.compoundInterestFET_whole);

            console.log(
                `${key},${user.pubkey},${user.fetchAddr},${principal
                    .add(compound)
                    .toFixed()},${principal.toFixed()},${compound.toFixed()}`
            );
        }
    } finally {
        web3.currentProvider.connection.close();
    }
}

main();

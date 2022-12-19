import { sha256 } from "@noble/hashes/sha256";
import { execSync } from "child_process";
import * as fs from "fs";
import {
    fromBase64,
    fromUtf8,
    MsgExecuteContract,
    ProposalType,
    SecretNetworkClient,
    toBase64,
    toHex,
    toUtf8,
    Tx,
    TxResultCode,
    Wallet,
} from "secretjs";
import { MsgSend } from "secretjs/dist/protobuf_stuff/cosmos/bank/v1beta1/tx";
import { AminoWallet } from "secretjs/dist/wallet_amino";
import {
    ibcDenom,
    sleep,
    storeContracts,
    waitForBlocks,
    waitForIBCChannel,
    waitForIBCConnection,
    Contract,
    instantiateContracts,
    cleanBytes,
} from "./utils";

type Account = {
    address: string;
    mnemonic: string;
    walletAmino: AminoWallet;
    walletProto: Wallet;
    secretjs: SecretNetworkClient;
};

const accountsCount = 1;

// @ts-ignore
// accounts on secretdev-1
const accounts: Account[] = new Array(accountsCount);
const contracts = {
    "simple": {
        v1: new Contract("v1"),
    },
};


let v1Wasm: Uint8Array;

// let readonly: SecretNetworkClient;

beforeAll(async () => {
    const mnemonics = [
        "grant rice replace explain federal release fix clever romance raise often wild taxi quarter soccer fiber love must tape steak together observe swap guitar",
        "jelly shadow frog dirt dragon use armed praise universe win jungle close inmate rain oil canvas beauty pioneer chef soccer icon dizzy thunder meadow",
    ];

    // Create clients for all of the existing wallets in secretdev-1
    for (let i = 0; i < mnemonics.length; i++) {
        const mnemonic = mnemonics[i];
        const walletAmino = new AminoWallet(mnemonic);
        accounts[i] = {
            address: walletAmino.address,
            mnemonic: mnemonic,
            walletAmino,
            walletProto: new Wallet(mnemonic),
            secretjs: await SecretNetworkClient.create({
                grpcWebUrl: "http://localhost:9391",
                wallet: walletAmino,
                walletAddress: walletAmino.address,
                chainId: "secretdev-1",
            }),
        };
    }

    // Create temporary wallets to fit all other usages (See TXCount test)
    for (let i = mnemonics.length; i < accountsCount; i++) {
        const wallet = new AminoWallet();
        const [{ address }] = await wallet.getAccounts();
        const walletProto = new Wallet(wallet.mnemonic);

        accounts[i] = {
            address: address,
            mnemonic: wallet.mnemonic,
            walletAmino: wallet,
            walletProto: walletProto,
            secretjs: await SecretNetworkClient.create({
                grpcWebUrl: "http://localhost:9391",
                chainId: "secretdev-1",
                wallet: wallet,
                walletAddress: address,
            }),
        };
    }

    // Send 100k SCRT from account 0 to each of accounts 1-itrations

    // const { secretjs } = accounts[0];

    // readonly = await SecretNetworkClient.create({
    //     chainId: "secretdev-1",
    //     grpcWebUrl: "http://localhost:9091",
    // });

    //    await waitForBlocks("secretdev-1");

    // create a second validator for MsgRedelegate tests
    // const { validators } = await readonly.query.staking.validators({});
    // if (validators.length === 1) {
    //     tx = await accounts[1].secretjs.tx.staking.createValidator(
    //         {
    //             selfDelegatorAddress: accounts[1].address,
    //             commission: {
    //                 maxChangeRate: 0.01,
    //                 maxRate: 0.1,
    //                 rate: 0.05,
    //             },
    //             description: {
    //                 moniker: "banana",
    //                 identity: "papaya",
    //                 website: "watermelon.com",
    //                 securityContact: "info@watermelon.com",
    //                 details: "We are the banana papaya validator",
    //             },
    //             pubkey: toBase64(new Uint8Array(32).fill(1)),
    //             minSelfDelegation: "1",
    //             initialDelegation: { amount: "1", denom: "uscrt" },
    //         },
    //         { gasLimit: 100_000 }
    //     );
    //     expect(tx.code).toBe(TxResultCode.Success);
    // }
});

describe("Setup", () => {
    test("v1", async () => {
        v1Wasm = fs.readFileSync(
            `${__dirname}/contract-simple/contract.wasm`
        ) as Uint8Array;
        contracts["simple"].v1.codeHash = toHex(sha256(v1Wasm));

        console.log("Storing contracts on secretdev-1...");
        let tx: Tx = await storeContracts(accounts[0].secretjs, [v1Wasm]);

        contracts["simple"].v1.codeId = Number(
            tx.arrayLog.find((x) => x.key === "code_id").value
        );

        console.log("Instantiating contracts on simple...");
        tx = await instantiateContracts(accounts[0].secretjs, [
            contracts["simple"].v1
        ]);

        contracts["simple"].v1.address = tx.arrayLog.find(
            (x) => x.key === "contract_address"
        ).value;
        contracts["simple"].v1.ibcPortId =
            "wasm." + contracts["simple"].v1.address;

        try {
            fs.writeFileSync('contractAddress.txt', contracts["simple"].v1.address);
        } catch (err) {
            console.error(err);
        }
        try {
            fs.writeFileSync('codeHash.txt', contracts["simple"].v1.codeHash);
        } catch (err) {
            console.error(err);
        }

        console.log("Contract at ", contracts["simple"].v1.address, contracts["simple"].v1.codeHash)
    });
});
let addr = "";
let codehash = "";

try {
    const data = fs.readFileSync('contractAddress.txt', 'utf8');
    addr = data;
} catch (err) {
    // console.log(err)
}

try {
    const data = fs.readFileSync('codeHash.txt', 'utf8');
    codehash = data;
} catch (err) {
    // console.log(err)
}

describe("Update", () => {
    describe("Send", () => {
        test("v1", async () => {
            console.log("Updating Store1 on contract at ", addr, codehash)
            const tx = await accounts[0].secretjs.tx.compute.executeContract(
                {
                    sender: accounts[0].address,
                    contractAddress: addr,
                    codeHash: codehash,
                    msg: {
                        store1: {
                            message: "hello1"
                        },
                    }
                },
                {gasLimit: 250_000}
            );
            console.log("Store1 tx ", tx)
            if (tx.code !== TxResultCode.Success) {
                console.error(tx.rawLog);
            }
            expect(tx.code).toBe(TxResultCode.Success);
        });
    });
    describe("Read", () => {
        test("v1", async () => {
            console.log("Query Store1 on contract at ", addr, codehash)
            const result: any = await accounts[0].secretjs.query.compute.queryContract({
                contractAddress: addr,
                codeHash: codehash,
                query: {
                    store1_q: {
                    },
                },
            });
            console.log("Query Store1 result", result)
            expect(result).toBe("hello1");
        });
    });
});

describe("QueryNew", () => {
    test("v1", async () => {

        console.log("Query Store1 on contract at ", addr, codehash)
        const result: any = await accounts[0].secretjs.query.compute.queryContract({
            contractAddress: addr,
            codeHash: codehash,
            query: {
                store1_q: {
                },
            },
        });
        console.log("Query Store1 result ", result)
        expect(result).toBe("hello1");
    });
});

describe("QueryOld", () => {
    test("v1", async () => {

        console.log("Query Store1 on contract at ", addr, codehash)
        const result: any = await accounts[0].secretjs.query.compute.queryContract({
            contractAddress: addr,
            codeHash: codehash,
            query: {
                store1_q: {
                },
            },
        });
        console.log("Query Store1 result ", result)
        expect(result).toBe("init val 1");
    });
});


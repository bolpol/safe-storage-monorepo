import * as BN from "bn.js";

import { ethers, waffle } from "hardhat";
import { Signer, Contract } from "ethers";
import { use, assert } from "chai";
import { solidity } from "ethereum-waffle";
import {CoerceFunc} from "@ethersproject/abi/src.ts/abi-coder";
// import web3 from 'web3';
// import timeMachine from 'ganache-time-traveler';

// import { BigNumber } from "@ethersproject/bignumber/src.ts/bignumber";
// import {getAddress} from "ethers/lib/utils";

use(solidity);

const {
    time,
    expectEvent,
    expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');
const snapshot = require('@openzeppelin/test-helpers/src/snapshot');

const ONE_DAY: number = 60 * 60 * 24
const FEE_TO_ADDRESS: string = '0x0000000000000000000000000000000000000FEE'
const DEAD_ADDRESS: string = '0x000000000000000000000000000000000000dEaD'

function getTimestamp() {
    return Math.floor(Date.now() / 1000);
}

interface Status<Number> {
    EMPTY: number,
    INITIALIZED: number,
    CANCELLED: number,
    QUEUED: number,
    EXECUTED: number,
}

const status: Status<Number> = Object.freeze({
    EMPTY: 0,
    INITIALIZED: 1,
    CANCELLED: 2,
    QUEUED: 3,
    EXECUTED: 4,
})

describe("ALL", function () {
    let accounts: Signer[];

    let DEPLOYER: string
    let OWNER1: string
    let OWNER2: string
    let OWNER3: string
    let OWNER4: string
    let OTHER: string

    let DEPLOYER_SIGNER: Signer
    let OWNER1_SIGNER: Signer
    let OWNER2_SIGNER: Signer
    let OWNER3_SIGNER: Signer
    let OWNER4_SIGNER: Signer
    let OTHER_SIGNER: Signer

    // let helper: Contract

    let erc20Mock: Contract
    let erc721Mock: Contract
    let erc1155Mock: Contract

    let multisig: Contract
    let safeStorage: Contract
    let timelock: Contract

    before('Configuration',async function () {
        accounts = await ethers.getSigners();

        DEPLOYER_SIGNER = accounts[0];
        OWNER1_SIGNER = accounts[1];
        OWNER2_SIGNER = accounts[2];
        OWNER3_SIGNER = accounts[3];
        OWNER4_SIGNER = accounts[4];
        OTHER_SIGNER = accounts[5];

        DEPLOYER = await DEPLOYER_SIGNER.getAddress()
        OWNER1 = await OWNER1_SIGNER.getAddress()
        OWNER2 = await OWNER2_SIGNER.getAddress()
        OWNER3 = await OWNER3_SIGNER.getAddress()
        OWNER4 = await OWNER3_SIGNER.getAddress()
        OTHER = await OTHER_SIGNER.getAddress()

        const SafeStorage = await ethers.getContractFactory("SafeStorage");
        const Timelock = await ethers.getContractFactory("Timelock");
        const Multisig = await ethers.getContractFactory("Multisig");

        // const feeTo: string = FEE_TO_ADDRESS
        // const serviceFee: number = 100 // 10%
        // const sellerBonusFee: number = 500 // 50%
        // const minBidStep: number = 1_000_000_000_000_000
        // const timeframe: number = 60 * 60 // 1 hr.

        // auction = await WeirdAuction.deploy(
        //     feeTo,
        //     serviceFee,
        //     sellerBonusFee,
        //     minBidStep,
        //     timeframe
        // );
        //
        // const Helper = await ethers.getContractFactory("Helper");
        // helper = await Helper.deploy();
        // time
    });

    // let snapshotA: any
    //
    // beforeEach(async () => {
    //     snapshotA = await snapshot()
    // })
    //
    // afterEach(async () => {
    //     snapshotA.restore()
    // })

    describe("main tests", function () {
        beforeEach(async () => {
            // const ERC721Mock = await ethers.getContractFactory("ERC721Mock");
            // base721Token = await ERC721Mock.deploy();
            // const ERC1155Mock = await ethers.getContractFactory("ERC1155Mock");
            // base1155Token = await ERC1155Mock.deploy();
            //
            // await base1155Token.connect(OWNER_SIGNER).mint(OWNER, 1, 200, "0x")
            // await base1155Token.connect(OWNER_SIGNER).setFee(1, [{recipient: OWNER, value: feeAbsolutePercent}])
            // await base1155Token.connect(OWNER_SIGNER).setApprovalForAll(auction.address, true)
            // await base1155Token.connect(OWNER_SIGNER).setApprovalForAll(SELLER, true)
            // await base1155Token.connect(SELLER_SIGNER).safeTransferFrom(OWNER, SELLER, 1, 100, "0x")
            // await base1155Token.connect(SELLER_SIGNER).setApprovalForAll(auction.address, true)
            const SafeStorage = await ethers.getContractFactory("SafeStorage");
            safeStorage = await SafeStorage.deploy()

            const Timelock = await ethers.getContractFactory("Timelock");
            timelock = await Timelock.deploy(safeStorage.address, DEPLOYER, 60*60*6);

            await safeStorage.transferOwnership(timelock.address)

            const Multisig = await ethers.getContractFactory("Multisig");
            multisig = await Multisig.deploy(timelock.address, [OWNER1, OWNER2, OWNER3, OWNER4])

            await timelock.transferOwnership(multisig.address)
        })

        it('create and queued proposal', async () => {
            let targets: Array<string> = [OTHER]
            let values: Array<string|number> = [1]
            let signatures: Array<string> = ['']
            let calldatas: Array<string> = ['0x']
            let description: string = ''
            let callFrom: string = safeStorage.address

            assert.equal((await timelock.safeStorage()).toString(), safeStorage.address, "safeStorage.address")
            assert.equal(Number(await multisig.requiredSigns()), 3, "requiredSigns")

            await multisig.connect(OWNER1_SIGNER).createAndSign(
                targets,
                values,
                signatures,
                calldatas,
                description,
                callFrom
            )

            let proposalId = await multisig.proposalCount()

            console.log(proposalId)

            assert.equal(Number(proposalId), 1, "Proposal not updated")
            assert.equal(await multisig.getStatus(proposalId), status.INITIALIZED, "Status not updated")

            let proposal = await multisig.proposals(Number(proposalId))

            // assert.equal(Number(proposal.id), Number(proposalId), "proposal.id")
            assert.equal(Number(proposal.signs), 1, "proposal.signs")

            //
            // await multisig.connect(OWNER2_SIGNER).sign(proposalId)
            // proposal = await multisig.proposals(Number(proposalId))

            // assert.equal(Number(proposal.signs), 2, "proposal.signs")

            let res = await multisig.connect(OWNER3_SIGNER).sign(proposalId)
            const events = (await res.wait()).events;

            events.map(({ args, event }: any) => {
                if (event == "Withdrawn") {
                    console.log(`Withdrawn:`);
                    console.log(args[0].toString());
                    console.log(args[1].toString());
                    console.log("");
                }
            });
        })

        it('create and execute proposal, withdraw eth', async () => {
            let targets: Array<string> = [OTHER]
            let values: Array<string|number> = [1]
            let signatures: Array<string> = ['']
            let calldatas: Array<string> = ['0x']
            let description: string = 'withdraw 1 wei'
            let callFrom: string = safeStorage.address

            assert.equal((await timelock.safeStorage()).toString(), safeStorage.address, "safeStorage.address")
            assert.equal(Number(await multisig.requiredSigns()), 3, "requiredSigns")

            await multisig.connect(OWNER1_SIGNER).createAndSign(
                targets,
                values,
                signatures,
                calldatas,
                description,
                callFrom
            )

            let proposalId = await multisig.proposalCount()

            await multisig.connect(OWNER2_SIGNER).sign(proposalId)
            await multisig.connect(OWNER3_SIGNER).sign(proposalId) // 3/4

            let proposal = await multisig.proposals(Number(proposalId))

            // assert.equal(Number(proposal.id), Number(proposalId), "proposal.id")
            assert.notEqual(Number(proposal.eta), 0, "proposal.eta")

            // const events = (await res.wait()).events;

            // events.map(({ args, event }: any) => {
            //     if (event == "Withdrawn") {
            //         console.log(`Withdrawn:`);
            //         console.log(args[0].toString());
            //         console.log(args[1].toString());
            //         console.log("");
            //     }
            // });

            console.log(await time)

            let delay = Number(await timelock.delay());

            console.log(Number(proposal.eta))
            console.log(delay)
            console.log(Number(proposal.eta) + 1000 + delay)

            await time.increaseTo(Number(proposal.eta) + 1000);
            //await time.advanceBlockTo(Number(await time.latestBlock()) + 1)

            assert.equal(await multisig.getStatus(Number(proposalId)), status.QUEUED, "status.QUEUED")

            await multisig.connect(OWNER3_SIGNER).execute(Number(proposalId), false, {value: 1})

            assert.equal(await multisig.getStatus(Number(proposalId)), status.EXECUTED, "status.EXECUTED")

            // await expectRevert(
            //     multisig.connect(OWNER3_SIGNER).execute(Number(proposalId), {value: 1}),
            //     'bed str'
            // )
        })

        it('create and execute proposal, withdraw erc20', async () => {
            const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
            const erc20Token = await ERC20Mock.deploy();

            await erc20Token.mint(safeStorage.address, 100);

            assert.equal(Number(await erc20Token.balanceOf(safeStorage.address)), 100, 'Wrong balance')

            // const { CoerceFunc } = ethers.utils.AbiCoder.CoerceFunc
            let abiCoder = new ethers.utils.AbiCoder()

            console.log(OTHER)
            console.log(abiCoder.encode(['address', 'uint'], [OTHER, 100]))

            let targets: Array<string> = [erc20Token.address]
            let values: Array<string|number> = [0]
            // let signatures: Array<string> = ['name()']
            // let calldatas: Array<string> = ['0x']
            // let signatures: Array<string> = ['transfer(address,uint)']
            let signatures: Array<string> = ['']
            // let calldatas: Array<string> = [`${abiCoder.encode(['address', 'uint'], [OTHER, 100])}`]
            let calldatas: Array<string> = [`0xa9059cbb00000000000000000000000015d34aaf54267db7d7c367839aaf71a00a2c6a650000000000000000000000000000000000000000000000000000000000000064`]
            let description: string = 'transfer ERC20 tokens'
            let callFrom: string = safeStorage.address

            assert.equal((await timelock.safeStorage()).toString(), safeStorage.address, "safeStorage.address")
            assert.equal(Number(await multisig.requiredSigns()), 3, "requiredSigns")

            await multisig.connect(OWNER1_SIGNER).createAndSign(
                targets,
                values,
                signatures,
                calldatas,
                description,
                callFrom
            )

            let proposalId = await multisig.proposalCount()

            await multisig.connect(OWNER2_SIGNER).sign(proposalId)
            await multisig.connect(OWNER3_SIGNER).sign(proposalId) // 3/4

            let proposal = await multisig.proposals(Number(proposalId))
            let actions = await multisig.getActions(Number(proposalId))

            console.log(proposal)
            console.log(actions)

            // assert.equal(Number(proposal.id), Number(proposalId), "proposal.id")
            assert.notEqual(Number(proposal.eta), 0, "proposal.eta")

            // const events = (await res.wait()).events;

            // events.map(({ args, event }: any) => {
            //     if (event == "Withdrawn") {
            //         console.log(`Withdrawn:`);
            //         console.log(args[0].toString());
            //         console.log(args[1].toString());
            //         console.log("");
            //     }
            // });

            let delay = Number(await timelock.delay());

            console.log(Number(proposal.eta))
            console.log(delay)
            console.log(Number(proposal.eta) + 1000 + delay)

            await time.increaseTo(Number(proposal.eta) + 1000);
            //await time.advanceBlockTo(Number(await time.latestBlock()) + 1)

            assert.equal(await multisig.getStatus(Number(proposalId)), status.QUEUED, "status.QUEUED")

            await multisig.connect(OWNER3_SIGNER).execute(Number(proposalId), false, {value: 0})

            // await expectRevert(multisig.connect(OWNER3_SIGNER).execute(Number(proposalId), false, {value: 0}), 'xxx')

            console.log(Number(await erc20Token.balanceOf(safeStorage.address)))
            assert.equal(Number(await erc20Token.balanceOf(OTHER)), 100, 'Wrong balance receipt')
        })

        it('erc1155, erc721 acceptance check', async () => {
            const ERC721Mock = await ethers.getContractFactory("ERC721Mock");
            const ERC1155Mock = await ethers.getContractFactory("ERC1155Mock");

            const erc721Token = await ERC721Mock.deploy();
            const erc1155Token = await ERC1155Mock.deploy();

            await erc721Token.mint(safeStorage.address, 1);
            await erc1155Token.mint(safeStorage.address, 1, 100, "0x");

            assert.equal(Number(await erc721Token.balanceOf(safeStorage.address)), 1, 'Wrong balance')
            assert.equal(Number(await erc1155Token.balanceOf(safeStorage.address, 1)), 100, 'Wrong balance')
        })

    })
})
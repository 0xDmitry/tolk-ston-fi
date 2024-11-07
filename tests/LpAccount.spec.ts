import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { Cell, toNano } from '@ton/core';
import { LpAccount } from '../wrappers/LpAccount';
import '@ton/test-utils';
import { compile } from '@ton/blueprint';

describe('LpAccount', () => {
    let code: Cell;

    beforeAll(async () => {
        code = await compile('LpAccount');
    });

    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let lpAccount: SandboxContract<LpAccount>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        lpAccount = blockchain.openContract(LpAccount.createFromConfig({}, code));

        deployer = await blockchain.treasury('deployer');

        const deployResult = await lpAccount.sendDeploy(deployer.getSender(), toNano('0.05'));

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: lpAccount.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and lpAccount are ready to use
    });
});

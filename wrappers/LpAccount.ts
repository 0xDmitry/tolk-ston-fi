import { Address, beginCell, Cell, Contract, contractAddress, ContractProvider, Sender, SendMode } from '@ton/core';

export type LpAccountConfig = {};

export function lpAccountConfigToCell(config: LpAccountConfig): Cell {
    return beginCell().endCell();
}

export class LpAccount implements Contract {
    constructor(readonly address: Address, readonly init?: { code: Cell; data: Cell }) {}

    static createFromAddress(address: Address) {
        return new LpAccount(address);
    }

    static createFromConfig(config: LpAccountConfig, code: Cell, workchain = 0) {
        const data = lpAccountConfigToCell(config);
        const init = { code, data };
        return new LpAccount(contractAddress(workchain, init), init);
    }

    async sendDeploy(provider: ContractProvider, via: Sender, value: bigint) {
        await provider.internal(via, {
            value,
            sendMode: SendMode.PAY_GAS_SEPARATELY,
            body: beginCell().endCell(),
        });
    }
}

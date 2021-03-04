const { BN, expectEvent, expectRevert, time } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const Token        = artifacts.require('ERC20PresetFixedSupply');
const Governance   = artifacts.require('Governance');
const CallReceiver = artifacts.require('CallReceiver');

contract('Governance - schedule', function (accounts) {
  const [ owner ] = accounts;

  const name        = 'BosonGovernance'
  const version     = '0.0.1';
  const tokenName   = 'MockToken';
  const tokenSymbol = 'MTKN';
  const tokenSupply = web3.utils.toWei('100');

  before(async () => {});

  beforeEach(async () => {
    this.token      = await Token.new(tokenName, tokenSymbol, tokenSupply, owner);
    this.governance = await Governance.new(name, version, this.token.address);
    this.receiver   = await CallReceiver.new();
  });

  describe('schedule', () => {
    it('valid proposal', async () => {
      const proposal = [
        [ this.receiver.address ],
        [ new BN('0') ],
        [ this.receiver.contract.methods.mockFunction().encodeABI() ],
        web3.utils.randomHex(32),
      ];
      const proposalid = await this.governance.hashProposal(...proposal);
      const { receipt } = await this.governance.propose(...proposal);
      expectEvent(receipt, 'TimerStarted', { timer: proposalid });
      expectEvent(receipt, 'Snapshot');
    });

    it('invalid proposal', async () => {
      const proposal = [
        [ this.receiver.address, this.receiver.address ],
        [ new BN('0') ],
        [ this.receiver.contract.methods.mockFunction().encodeABI() ],
        web3.utils.randomHex(32),
      ];
      const proposalid = await this.governance.hashProposal(...proposal);
      await expectRevert(
        this.governance.propose(...proposal),
        "GovernanceCore: invalid proposal length",
      );
    });

    it('empty proposal', async () => {
      const proposal = [
        [],
        [],
        [],
        web3.utils.randomHex(32),
      ];
      const proposalid = await this.governance.hashProposal(...proposal);
      await expectRevert(
        this.governance.propose(...proposal),
        "GovernanceCore: empty proposal",
      );
    });
  });
});

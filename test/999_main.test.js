const { BN, expectEvent, expectRevert, time } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const Token        = artifacts.require('ERC20PresetFixedSupply');
const Governance   = artifacts.require('Governance');
const CallReceiver = artifacts.require('CallReceiver');

async function getReceiptOrReason(promise, reason = undefined) {
  if (reason) {
    await expectRevert(promise, reason);
    return undefined;
  } else {
    const { receipt } = await promise;
    return receipt;
  }
}

function governanceWorkflow() {
  describe('with deposits', () => {
    beforeEach(async () => {
      this.receipts = {};
      this.id = await this.governance.hashProposal(...this.settings.proposal);

      // TODO REASON
      for (const voter of this.settings.voters) {
        this.token.approve(this.governance.address, voter.weight);
        this.governance.depositFor(voter.address, voter.weight);
      }
    });

    describe('with proposed', () => {
      beforeEach(async () => {
        if (this.settings.steps.propose.enable) {
          this.receipts.propose = await getReceiptOrReason(this.governance.propose(...this.settings.proposal), this.settings.steps.propose.reason);
        }
      });

      describe('with vote', () => {
        beforeEach(async () => {
          this.receipts.castVote = [];
          for (const voter of this.settings.voters) {
            this.receipts.castVote.push(
              await getReceiptOrReason(this.governance.castVote(this.id, voter.score, { from: voter.address }), voter.reason)
            )
          }
        });

        describe('after deadline', () => {
          beforeEach(async () => {
            ({ deadline: this.deadline } = await this.governance.viewProposal(this.id));
            if (this.settings.steps.wait.enable) {
              await time.increaseTo(this.deadline.addn(1));
            }
          });

          describe('with execute', () => {
            beforeEach(async () => {
              if (this.settings.steps.execute.enable) {
                this.receipts.execute = await getReceiptOrReason(this.governance.execute(...this.settings.proposal), this.settings.steps.execute.reason);
              }
            });

            it('check', async () => {
              await this.settings.check();
            });
          });
        });
      });
    });
  });
}

contract('Governance', function (accounts) {
  const [ owner, other ] = accounts;
  const name        = 'BosonGovernance'
  const version     = '0.0.1';
  const tokenName   = 'MockToken';
  const tokenSymbol = 'MTKN';
  const tokenSupply = web3.utils.toWei('100');

  beforeEach(async () => {
    this.token      = await Token.new(tokenName, tokenSymbol, tokenSupply, accounts[0]);
    this.governance = await Governance.new(name, version, this.token.address);
    this.receiver   = await CallReceiver.new();
  });

  describe('good', () => {
    beforeEach(async () => {
      this.settings = {
        proposal: [
          [ this.receiver.address ],
          [ new BN('0') ],
          [ this.receiver.contract.methods.mockFunction().encodeABI() ],
          web3.utils.randomHex(32),
        ],
        voters: [
          { address: owner, weight: web3.utils.toWei('1'), score: new BN('100') },
          { address: other, weight: web3.utils.toWei('1'), score: new BN('40')  },
        ],
        steps: {
          propose: { enable: true },
          wait:    { enable: true },
          execute: { enable: true },
        },
        check: async () => {
          expectEvent(this.receipts.propose, 'TimerStarted', { timer: this.id, deadline: this.deadline });
          // expectEvent(this.receipts.castVote, 'TimerStarted', { timer: this.id, deadline: this.deadline });
          expectEvent(this.receipts.execute, 'TimerReset', { timer: this.id });
          expectEvent(this.receipts.execute, 'TimerLocked', { timer: this.id });
          expectEvent.inTransaction(this.receipts.execute.transactionHash,
            this.receiver,
            'MockFunctionCalled',
          );

          await expectRevert(this.governance.castVote(this.id, new BN('0'), { from: accounts[2] }), "GovernanceCore: vote not currently active");
        }
      }
    });
    governanceWorkflow();
  });

  describe('missing proposal', () => {
    beforeEach(async () => {
      this.settings = {
        proposal: [
          [ this.receiver.address ],
          [ new BN('0') ],
          [ this.receiver.contract.methods.mockFunction().encodeABI() ],
          web3.utils.randomHex(32),
        ],
        voters: [
          { address: owner, weight: web3.utils.toWei('1'), score: new BN('100'), reason: 'GovernanceCore: vote not currently active' },
          { address: other, weight: web3.utils.toWei('1'), score: new BN('40'),  reason: 'GovernanceCore: vote not currently active' },
        ],
        steps: {
          propose: { enable: false },
          wait:    { enable: false },
          execute: { enable: true, reason: 'GovernanceCore: proposal not ready to execute' },
        },
        check: () => {}
      }
    });
    governanceWorkflow();
  });

  describe('double cast', () => {
    beforeEach(async () => {
      this.settings = {
        proposal: [
          [ this.receiver.address ],
          [ new BN('0') ],
          [ this.receiver.contract.methods.mockFunction().encodeABI() ],
          web3.utils.randomHex(32),
        ],
        voters: [
          { address: owner, weight: web3.utils.toWei('1'), score: new BN('100') },
          { address: owner, weight: web3.utils.toWei('1'), score: new BN('100'), reason: 'GovernanceCore: vote already casted' },
        ],
        steps: {
          propose: { enable: true },
          wait:    { enable: true },
          execute: { enable: true },
        },
        check: () => {}
      }
    });
    governanceWorkflow();
  });

  describe('quorum not reached', () => {
    beforeEach(async () => {
      this.settings = {
        proposal: [
          [ this.receiver.address ],
          [ new BN('0') ],
          [ this.receiver.contract.methods.mockFunction().encodeABI() ],
          web3.utils.randomHex(32),
        ],
        voters: [
          { address: owner, weight: web3.utils.toWei('0'), score: new BN('100') },
          { address: other, weight: web3.utils.toWei('0'), score: new BN('40') },
        ],
        steps: {
          propose: { enable: true },
          wait:    { enable: true },
          execute: { enable: true, reason: 'GovernanceCore: quorum not reached' },
        },
        check: () => {}
      }
    });
    governanceWorkflow();
  });

  describe('score not reached', () => {
    beforeEach(async () => {
      this.settings = {
        proposal: [
          [ this.receiver.address ],
          [ new BN('0') ],
          [ this.receiver.contract.methods.mockFunction().encodeABI() ],
          web3.utils.randomHex(32),
        ],
        voters: [
          { address: owner, weight: web3.utils.toWei('1'), score: new BN('0') },
          { address: other, weight: web3.utils.toWei('1'), score: new BN('0') },
        ],
        steps: {
          propose: { enable: true },
          wait:    { enable: true },
          execute: { enable: true, reason: 'GovernanceCore: required score not reached' },
        },
        check: () => {}
      }
    });
    governanceWorkflow();
  });

  describe('vote not over', () => {
    beforeEach(async () => {
      this.settings = {
        proposal: [
          [ this.receiver.address ],
          [ new BN('0') ],
          [ this.receiver.contract.methods.mockFunction().encodeABI() ],
          web3.utils.randomHex(32),
        ],
        voters: [
          { address: owner, weight: web3.utils.toWei('1'), score: new BN('100') },
        ],
        steps: {
          propose: { enable: true },
          wait:    { enable: false },
          execute: { enable: true, reason: 'GovernanceCore: proposal not ready to execute' },
        },
        check: () => {}
      }
    });
    governanceWorkflow();
  });
});

const { BN, expectEvent, expectRevert, time } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const Token        = artifacts.require('ERC20PresetFixedSupply');
const CompWrapper  = artifacts.require('CompWrapper');
const Governance   = artifacts.require('Governance');
const CallReceiver = artifacts.require('CallReceiver');

contract('Governance', function (accounts) {
  const [ owner ] = accounts;

  const name        = 'BosonGovernance'
  const version     = '0.0.1';
  const tokenName   = 'MockToken';
  const tokenSymbol = 'MTKN';
  const tokenSupply = web3.utils.toWei('100');

  before(async () => {});

  beforeEach(async () => {
    this.token      = await Token.new(tokenName, tokenSymbol, tokenSupply, owner);
    this.comp       = await CompWrapper.new(this.token.address);
    this.governance = await Governance.new(name, version, this.comp.address);
    this.receiver   = await CallReceiver.new();
  });

  describe('workflow', () => {
    beforeEach(async () => {
      this.voteWeight = web3.utils.toWei('10');
      this.voteScore  = new BN('100');
      await this.token.approve(this.comp.address, this.voteWeight);
      await this.comp.depositFor(owner, this.voteWeight);
    });

    describe('with proposal', () => {
      beforeEach(async () => {
        this.proposal = [
          [ this.receiver.address ],
          [ new BN('0') ],
          [ this.receiver.contract.methods.mockFunction().encodeABI() ],
          web3.utils.randomHex(32),
        ];
        this.id = await this.governance.hashProposal(...proposal);
        this.receipts = {};
      });

      describe('with proposed', () => {
        beforeEach(async () => {
          ({ receipt: this.receipts.propose } = await this.governance.propose(...this.proposal));
          expectEvent(this.receipts.propose, 'TimerStarted');
          expectEvent(this.receipts.propose, 'Proposed');
        });

        describe('with vote', () => {
          beforeEach(async () => {
            ({ receipt: this.receipts.castVote } = await this.governance.castVote(this.id, this.voteScore));
            expectEvent(this.receipts.castVote, 'Vote');
          });

          describe('after deadline', () => {
            beforeEach(async () => {
              ({ deadline: this.deadline } = await this.governance.viewProposal(this.id));
              await time.increaseTo(this.deadline.addn(1));
            });

            describe('with execute', () => {
              beforeEach(async () => {
                ({ receipt: this.receipts.execute } = await this.governance.execute(...this.proposal));
                expectEvent(this.receipts.execute, 'TimerReset');
                expectEvent(this.receipts.execute, 'TimerLocked');
                expectEvent(this.receipts.execute, 'Executed');
              });

              it('post check', async () => {
                expectEvent(this.receipts.propose, 'TimerStarted', {
                  timer:    this.id,
                  deadline: this.deadline,
                });
                expectEvent(this.receipts.propose, 'Proposed', {
                  id:       this.id,
                  target:   this.proposal[0],
                  // value:    this.proposal[1],
                  data:     this.proposal[2],
                  salt:     this.proposal[3],
                });
                expectEvent(this.receipts.castVote, 'Vote', {
                  id:       this.id,
                  account:  owner,
                  balance:  this.voteWeight,
                  score:    this.voteScore,
                });
                expectEvent(this.receipts.execute, 'TimerReset', {
                  timer:    this.id,
                });
                expectEvent(this.receipts.execute, 'TimerLocked', {
                  timer:    this.id,
                });
                expectEvent(this.receipts.execute, 'Executed', {
                  id:       this.id,
                });
                expectEvent.inTransaction(this.receipts.execute.transactionHash,
                  this.receiver,
                  'MockFunctionCalled',
                );
              });
            });
          });
        });
      });
    });
  });
});

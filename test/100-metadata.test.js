const { BN, expectEvent, expectRevert, time } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const Token        = artifacts.require('ERC20PresetFixedSupply');
const Governance   = artifacts.require('Governance');
const CallReceiver = artifacts.require('CallReceiver');

contract('Governance - metadata', function (accounts) {
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

  describe('metadata', () => {
    it('token', async () => {
      expect(await this.token.name()).to.be.equal(tokenName);
      expect(await this.token.symbol()).to.be.equal(tokenSymbol);
      expect(await this.token.totalSupply()).to.be.bignumber.equal(tokenSupply);
    });

    it('governance', async () => {
      expect(await this.governance.name()).to.be.equal('Stacked ' + tokenName);
      expect(await this.governance.symbol()).to.be.equal('S-' + tokenSymbol);
      expect(await this.governance.totalSupply()).to.be.bignumber.equal('0');
      expect(await this.governance.votingDuration()).to.be.bignumber.equal('3600');
      expect(await this.governance.quorum()).to.be.bignumber.equal('1');
      expect(await this.governance.maxScore()).to.be.bignumber.equal('100');
      expect(await this.governance.requiredScore()).to.be.bignumber.equal('50');
    });
  });
});

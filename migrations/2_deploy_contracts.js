var Arianee = artifacts.require('./arianeeStore.sol');

module.exports = function(deployer) {
  deployer.deploy(Arianee,'0x841d01c859355fde1f36a9ce0951de5a10802110','0x841d01c859355fde1f36a9ce0951de5a10802110','0x841d01c859355fde1f36a9ce0951de5a10802110');
  //deployer.link(ConvertLib, MetaCoin);
  //deployer.deploy(MetaCoin);
};
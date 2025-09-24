const { deploy } = require("@openzeppelin/hardhat-upgrades/dist/utils");

require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  namedAccounts: {
    deployer: 0, // 部署者账户，默认是第一个账户
    user1: 1, // 第二个账户作为user1
    user2: 2, // 第三个账户作为user2
  }
};
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});
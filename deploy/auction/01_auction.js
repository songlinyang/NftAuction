const { deployments,upgrades, getNamedAccounts, ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");
module.exports = async({getNamedAccounts,deployments}) => {
    const { save } = deployments;
    const { deployer } = await getNamedAccounts();
    console.log("部署当前拍卖合约模版的msg.sender：",deployer);
    const nftAuction = await ethers.getContractFactory("SaleNftAuction");
    const nftAuctionProxy = await upgrades.deployProxy(nftAuction,[deployer],{
        initializer: 'initialize'  //指定初始化函数
    });
    await nftAuctionProxy.waitForDeployment();
    const proxyAddress = await nftAuctionProxy.getAddress();
    console.log("Auction 代理合约地址：",proxyAddress);

    const nftAuctionAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log("Auction 实现合约地址：",nftAuctionAddress);
    // 保存合约和代理合约地址到json文件中
    const storePath = path.join(__dirname, "./.cache/proxyNftAuction.json");
    // 序列化对象，写入json文件，提供合约升级时反序列化进行调用
    fs.writeFileSync(
        storePath,
        JSON.stringify({
        proxyAddress,
        nftAuctionAddress,
        abi:nftAuction.interface.format("json")  //将nft合约的abi保存下来
        })
    );
    await save("NftAuctionProxy", {
        abi:nftAuction.interface.format("json"), //将nft合约的abi保存下来
        address: proxyAddress
    });

}

module.exports.tags= ["deploySaleNftAuction"];
const { ethers,upgrades } = require("hardhat");
const fs = require("fs");
const path = require("path");
module.exports = async ({ getNamedAccounts, deployments }) => {
    const { save } = deployments;
    const { deployer } = await getNamedAccounts();
    console.log("部署用户地址:", deployer);

    //读取 .cache/json文件，对对象进行反序列化
    const storePath = path.resolve(__dirname,"./.cache/proxyNftAuction.json");
    const storeData = fs.readFileSync(storePath,"utf-8");
    const { proxyAddress,nftAuctionAddress,abi } = JSON.parse(storeData);
    //合约升级,升级版V2合约
    const nftAuctionV2  = await ethers.getContractFactory("SaleNftAuctionV2");

    //升级代理合约
    const nftAuctionProxyV2 = await upgrades.upgradeProxy(proxyAddress,nftAuctionV2);
    await nftAuctionProxyV2.waitForDeployment();
    const proxyAddressV2 = await nftAuctionProxyV2.getAddress();
    // const implAddressV2 = await upgrades.erc1967.getImplementationAddress(proxyAddressV2);
    console.log("V2升级后代理合约地址:", proxyAddressV2);
    //保存
    await save("NftAuctionProxyV2", {
        abi:nftAuctionV2.interface.format("json"), //将nft合约的abi保存下来,
        address: proxyAddressV2
    });
}

module.exports.tags = ["upgradeNftAuction"];

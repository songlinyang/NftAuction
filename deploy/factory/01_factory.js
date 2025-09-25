const { ethers,deployments,upgrades, getNamedAccounts } = require("hardhat");

module.exports = async({getNamedAccounts,deployments}) =>{
    const { save } = deployments;
    const { deployer } = await getNamedAccounts();
    console.log("部署当前工厂合约的msg.sender:",deployer);
    
    const auctionFactory = await ethers.getContractFactory("SaleFactory");
    const auctionFactoryProxy = await upgrades.deployProxy(auctionFactory,[],{
        initializer: 'initialize'  //指定初始化函数
    });

    await auctionFactoryProxy.waitForDeployment();
    const factoryProxyAddress =  await auctionFactoryProxy.getAddress();
    console.log("工厂合约代理地址：",factoryProxyAddress);

    const auctionFactoryAddress = await upgrades.erc1967.getImplementationAddress(factoryProxyAddress);
    console.log("工厂合约逻辑地址：",auctionFactoryAddress);


    await save("AuctionFactoryProxy", {
        abi:auctionFactory.interface.format("json"),
        address: factoryProxyAddress
    });

}

module.exports.tags = ["deployAuctionFactory"];
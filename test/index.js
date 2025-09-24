const { ethers }   = require("hardhat");
const { expect }  = require("chai");


describe("MyNftSaleMarket", async ()=> {
    //测试用例1: 部署ERC721合约
    const name = "MyNFT";
    const symbol = "MNFT";
    let deployermyNft;
    it("部署ERC721合约", async function() {
        const MyNft = await ethers.getContractFactory("MyNFT");
        myNft = await MyNft.deploy(name, symbol);
        await myNft.waitForDeployment();
        //获取合约地址
        const myNftAddress = await myNft.getAddress();
        console.log("MyNFT deployed to:", myNftAddress);
        //获取合约deploy 账户
        const [deployer] = await ethers.getSigners();
        console.log("MyNFT deployer is:", deployer.address);
        //断言合约名称和符号
        expect(await myNft.name()).to.equal(name);
        expect(await myNft.symbol()).to.equal(symbol);
    });
    
});
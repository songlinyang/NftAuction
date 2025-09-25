const { expect }  = require("chai");
const { ethers, deployments } = require("hardhat");

describe("MyNftSaleMarketUpdate", async ()=> {
    it("update v2",async()=>{
        //1.部署业务合约
        await deployments.fixture(["deployNftAuction"]);
        
        const nftAuctionProxy = await deployments.get("NftAuctionProxy");
        //2.调用createAuction 方法创建拍卖
        const nftAuction = await ethers.getContractAt("NftAuction",nftAuctionProxy.address);
        await nftAuction.createAuction(
            100*1000,
            ethers.parseEther("0.01"),
            ethers.ZeroAddress,
            1
        );
        //升级前Auction的状态
        const auction = await nftAuction.auctions(0);
        console.log("创建拍卖成功，拍卖信息：", auction);
        //3.升级合约
        await deployments.fixture(["upgradeNftAuction"]);
        const nftAuction2 = await ethers.getContractAt("NftAuctionV2",nftAuctionProxy.address);  

        //升级后Auction的状态，应该能记录升级前的
        const auction2 = await nftAuction2.auctions(0);
        const helloFunc = await nftAuction2.testHello();
        console.log("调用升级后合约的testHello方法:", helloFunc);
        console.log("升级后拍卖信息：", auction2);
        //4.读取合约的Auction状态 Auction[0]
        expect(auction2.startPrice).to.equal(auction.startPrice);
    });
});
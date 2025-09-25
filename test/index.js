const { expect }  = require("chai");
const { ethers, deployments } = require("hardhat");


describe("MyNftSaleMarket", async ()=> {
    //测试用例1: 部署ERC721合约
    const name = "MyNFT";
    const symbol = "MNFT";
    // ETH->USDC 价格预言机合约地址 0x694AA1769357215DE4FAC081bf1f309aDC325306 喂价 
    const chainlinkFeedAddress = "0x694AA1769357215DE4FAC081bf1f309aDC325306";
    let deployermyNftAddress;
    let deployermyNft;
    let singer,buyer;
    beforeEach(async ()=>{
        const MyNft = await ethers.getContractFactory("MyNFT");
        const myNft = await MyNft.deploy(name, symbol);
        await myNft.waitForDeployment();
        //获取合约地址
        const myNftAddress = await myNft.getAddress();
        console.log("MyNFT address to:", myNftAddress);
        //获取合约deploy 账户
        const [deployer] = await ethers.getSigners();
        console.log("获取当前部署合约的msg.sender:", deployer.address);

        //3.铸币 给 singer
        [singer,buyer] = await ethers.getSigners();
        await myNft.connect(singer).awardItem(singer.getAddress(),"https://bafybeihyhbzkkm7h6fkbsyieg2vt4uzihcpfjx7vvwjhjjtbwldibqsrqq.ipfs.dweb.link?filename=my-nft-metadata.json");
        console.log("singer address: ",singer.getAddress());
        //获取合约地址
        const nftAddress = await myNft.getAddress();

        console.log("获取NFT合约地址:",nftAddress)
        deployermyNftAddress = myNftAddress;
        deployermyNft = myNft;
    });
    it("部署ERC721合约部署测试", async function() {
        const MyNft = await ethers.getContractFactory("MyNFT");
        const myNft = await MyNft.deploy(name, symbol);
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
    it("部署拍卖合约模版", async function() {   


        //1.部署拍卖合约
        await deployments.fixture(["deploySaleNftAuction"]);
        const nftAuctionProxy = await deployments.get("NftAuctionProxy");
        const nftAuction = await ethers.getContractAt("SaleNftAuction",nftAuctionProxy.address);
    
        // 2.部署工厂合约
        await deployments.fixture(["deployAuctionFactory"]);
        const auctionFactoryProxy = await deployments.get("AuctionFactoryProxy");
        //数据馈送
        const auctionFactory = await ethers.getContractAt("SaleFactory",auctionFactoryProxy.address);
        
        //创建 拍卖实例
        const _tokenId = 1;
        const _duration = 100*1000;
        const _startPrice = ethers.parseEther("0.01");

        const tx = await auctionFactory.connect(singer).createAuction(deployermyNftAddress,_tokenId, _duration, _startPrice);
        const receipt = await tx.wait();
        //获取从链上交易获取auctionAddr,auctionId
        const auctionAddr = await auctionFactory.auctions(_tokenId);
        // const auctionId = event.args._AuctionId;
        console.log("新拍卖合约地址：",auctionAddr);
        // console.log("新拍卖合约ID：",auctionId)

        const newNftAuction = await ethers.getContractAt("SaleNftAuction",auctionAddr);
        //断言工厂合约创建的新合同地址与tx交易对生成的一致
        const newNftAuctionAddress = await newNftAuction.getAddress();
        expect(auctionAddr).to.equal(newNftAuctionAddress);
        // 授权 SaleNftAuction 合约可以转移 singer 的 NFT
        await deployermyNft.connect(singer).approve(auctionAddr, 1);
        
        //开始拍卖
        const successTx = await newNftAuction.connect(singer).createAuctionSale(_duration,_startPrice,deployermyNftAddress,_tokenId);
        const successReceipt = await successTx.wait();
        //判断NFT是否被转给当前拍卖Auction合约
        expect(await deployermyNft.connect(singer).ownerOf(_tokenId)).to.equal(newNftAuctionAddress);
        //==================================判断初始化拍卖是否创建成功
        const auction = await newNftAuction.auctions(_tokenId-1);
        //卖家
        console.log(auction.seller);
        //拍卖结束时间
        console.log(auction.duration);
        //起始价格
        console.log(auction.startPrice);
        //开始时间
        console.log(auction.startTime);
        //是否结束
        console.log(auction.ended);
        //最高出价者
        console.log(auction.highestBidderAddr);
        //最高价格
        console.log(auction.highestBidAmount);
        //NFT合约地址
        console.log(auction.nftContract);
        //NFT ID
        console.log(auction.tokenId);
        //参与竞价的资产类型 0x 表示eth，其他地址均为erc20 ,
        console.log(auction.tokenAddress);
        //判断卖家是否为singer 即msg.sender
        expect(auction.seller).to.equal(singer.address);
        //==================================判断初始化拍卖结束

        //设置价格数据馈送源 支持ETH->USDC, ETH两种币出价
        //==================================开始喂价（需连测试网）
        console.log("买家地址：",buyer.address);
        const chainLinkTx = await newNftAuction.connect(singer).setAuctionPriceFeeds(buyer.address,chainlinkFeedAddress);
        const clReceipt = await chainLinkTx.wait();
        console.log(await newNftAuction.tokenPriceFeeds(buyer.address));
        const amount =1;
        const cltx = await newNftAuction.connect(singer).checkLatestprice(buyer.address);
        await cltx.wait();
        newNftAuction.once("CheckLatestprice",(tokenAddress,amount,bidPrice)=>{
            console.log("交易对创建成功！");
            console.log("价格馈送合约：：",tokenAddress);
            console.log("amount：：",amount);
            console.log("bidPrice：：",bidPrice);

        });
        //=========已喂价完成

        //开始出价
        const highAmount = 11000000000000000;
        const buyerBidTx = await newNftAuction.connect(singer).buyerBid(_tokenId-1,highAmount,buyer.address)
        await buyerBidTx.wait();
        const auctionHigh = await newNftAuction.auctions(_tokenId-1);
        //卖家
        console.log(auctionHigh.seller);
        //拍卖结束时间
        console.log(auctionHigh.duration);
        //起始价格
        console.log(auctionHigh.startPrice);
        //开始时间
        console.log(auctionHigh.startTime);
        //是否结束
        console.log(auctionHigh.ended);
        //最高出价者
        console.log(auctionHigh.highestBidderAddr);
        //最高价格
        console.log(auctionHigh.highestBidAmount);
        //NFT合约地址
        console.log(auctionHigh.nftContract);
        //NFT ID
        console.log(auctionHigh.tokenId);
        //参与竞价的资产类型 0x 表示eth，其他地址均为erc20 ,
        console.log(auctionHigh.tokenAddress);
        //判断最高出价者写入成功
        expect(auctionHigh.highestBidderAddr).to.equal(buyer.address);

        //等待拍卖超时 100秒
        await new Promise((resolve) => setTimeout(resolve, _duration));
        console.log("等待10秒钟，拍卖结束"); 

        //结束拍卖
        const endTx = await newNftAuction.connect(singer).endableAuction(deployermyNftAddress,_tokenId-1)
        await endTx.wait();
        const endAuction = await newNftAuction.auctions(_tokenId-1);
        //卖家
        console.log(endAuction.seller);
        //拍卖结束时间
        console.log(endAuction.duration);
        //起始价格
        console.log(endAuction.startPrice);
        //开始时间
        console.log(endAuction.startTime);
        //是否结束
        console.log(endAuction.ended);
        //最高出价者
        console.log(endAuction.highestBidderAddr);
        //最高价格
        console.log(endAuction.highestBidAmount);
        //NFT合约地址
        console.log(endAuction.nftContract);
        //NFT ID
        console.log(endAuction.tokenId);
        //参与竞价的资产类型 0x 表示eth，其他地址均为erc20 ,
        console.log(endAuction.tokenAddress);
        //判断拍卖是否结束
        expect(endAuction.ended).to.equal(true);
        //判断NFT是否被转到最高出价者账户
        expect(await deployermyNft.connect(singer).ownerOf(_tokenId)).to.equal(endAuction.highestBidderAddr);
    });
    
});
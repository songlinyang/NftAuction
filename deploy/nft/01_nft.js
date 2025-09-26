const { ethers } = require("hardhat");

module.exports = async()=>{
    const name = "MyNFT";
    const symbol = "MNFT";
    // ETH->USDC 价格预言机合约地址 0x694AA1769357215DE4FAC081bf1f309aDC325306 喂价 
    const tokenURI = "https://bafybeihyhbzkkm7h6fkbsyieg2vt4uzihcpfjx7vvwjhjjtbwldibqsrqq.ipfs.dweb.link?filename=my-nft-metadata.json";
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
    const [singer] = await ethers.getSigners();
    await myNft.connect(singer).awardItem(singer.getAddress(),tokenURI);
    console.log("singer address: ",singer.getAddress());
    //获取合约地址
    const nftAddress = await myNft.getAddress();

    console.log("获取NFT合约地址:",nftAddress)
}

module.exports.tags=["deployMyNft"];
pragma solidity ^0.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./libraries/MyConcat.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Impl/ISaleNftAuction.sol";
import "hardhat/console.sol";


/**
拍卖步骤：
1、创建拍卖
2、上架拍卖
3、用户发起拍卖
4、首次购入大于起拍价
5、出价阶段用户购入需大于拍卖最高价
6、拍卖有效期结束，拍卖结束，NFT转给最高价用户
7、流拍并下价拍卖
 */
 //拍卖合约

contract SaleNftAuction is Initializable,UUPSUpgradeable,IERC721Receiver,ISaleNftAuction{

    using MyConcat for uint256;
    address admin;
    //nft转账事件
    event NFTTransferred(address indexed nft, address indexed from, address indexed to, uint256 tokenId);
    //合约接收nft转账事件
    event ReceivedERC721(address operator, address from, uint256 tokenId, bytes data);
    //检查最新价格馈送情况
    event CheckLatestprice(address tokenAddress,uint256 amount,uint256 bidPrice);
    function initialize(address _initOwner) public initializer {
		admin = _initOwner;
    }
    //拍卖结构体
    struct Auction{
        //卖家
        address seller;
        //拍卖结束时间
        uint256 duration;
        //起始价格
        uint256 startPrice;
        //开始时间
        uint256 startTime;
        //是否结束
        bool ended;
        //最高出价者
        address highestBidderAddr;
        //最高价格
        uint256 highestBidAmount;
        //NFT合约地址
        address nftContract;
        //NFT ID
        uint256 tokenId;

        //参与竞价的资产类型 0x 表示eth，其他地址均为erc20 ,仅支持ETH->USDC,
        address tokenAddress;

    }
        // 下一个拍卖ID
    uint256 public nextAuctionId;
    mapping(address => AggregatorV3Interface) public tokenPriceFeeds;
    mapping(uint256 => Auction) public auctions;

    //设置价格数据馈送源
    function setAuctionPriceFeeds(address tokenAddress,address _priceETHFeed) external{
         require(admin==msg.sender,"admin error");
         tokenPriceFeeds[tokenAddress] = AggregatorV3Interface(_priceETHFeed);
    }
    //支持实时价格馈送
    function getChainlinkFeedLatestPrice(address tokenAddress) public view returns(int) {
        require(address(tokenPriceFeeds[tokenAddress]) != address(0), "Price feed not set");
        AggregatorV3Interface priceETHFeed = tokenPriceFeeds[tokenAddress];
        (
            /* uint80 roundId */,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = priceETHFeed.latestRoundData();
        return answer;
    }
    //自定义NFT转账到拍卖合约的功能+转账记录
    function safeNftTransferFrom(address _nftAddress,address from,address to,uint256 _tokenId) internal {
        require(_nftAddress!=address(0),"_nftAddress is not ERC721 type address");
        require(IERC721(_nftAddress).ownerOf(_tokenId)!=address(0),"nft _tokenId is not valid");
        IERC721(_nftAddress).safeTransferFrom(from, to, _tokenId);
        emit NFTTransferred(_nftAddress, from, to, _tokenId);
    }
    //步骤一创建拍卖：允许用户将NFT上架拍卖
    function createAuctionSale(uint256 _duration,uint256 _startPrice,address _nftAddress,uint256 _tokenId) external returns(bool){
        require(admin==msg.sender,"function not allow");
        require(_duration > 1000 * 60, "duration must be greater than 0");
        require(_startPrice>=0,"start Price should be greate than 0 or equal 0");
        //将NFT转入到合约中
        safeNftTransferFrom(_nftAddress,msg.sender, address(this), _tokenId);
        //创建拍卖
        auctions[nextAuctionId] = Auction({
        seller:msg.sender,
        duration:_duration,
        startPrice:_startPrice,
        startTime:block.timestamp,
        ended:false,
        highestBidderAddr:address(0),
        //最高价格
        highestBidAmount:0,
        //NFT合约地址
        nftContract:_nftAddress,
        //NFT ID
        tokenId:_tokenId,

        //参与竞价的资产类型 0x 表示eth，其他地址均为erc20 ,仅支持ETH->USDC,
        tokenAddress:address(0)
        });
        nextAuctionId+=1;
    }
    //下架拍卖(单个)
    function disableAuctionSaleOnlyOne(bool endable,uint256 _tokenId) external {
        //判断拍卖是否结束
        require(auctions[_tokenId].duration>=block.timestamp,"auctions is not valid");
        Auction storage disableAuction = auctions[_tokenId];
        disableAuction.ended = endable;
    }
    //出价：允许用户以ERC20或以太坊出价
    function buyerBid(uint256 _auctionId,uint256 amount,address _tokenAddress) external payable{
        Auction storage bidAuction = auctions[_auctionId];
        //判断当前出价拍卖是否结束
        require(bidAuction.ended!=true && bidAuction.startTime+bidAuction.duration>block.timestamp,"auctions is endable!");
        //判断当前出价价格，是否低于拍卖价 并且是否低于最高价
        require(bidAuction.startPrice<amount && amount>bidAuction.highestBidAmount,"bid price is valid,please check bid amount is greate than auctionStartPrice or highestBidAmount");
        uint256 bidPrice;
        if (_tokenAddress !=address(0)){
            //出价类型为ERC20
            //需要接入chainlink进行价格反馈，且存在decimal
            //换算成美元价格

            bidPrice = amount * uint(getChainlinkFeedLatestPrice(_tokenAddress));
        }else{
            //出价类型为ETH
            amount = msg.value;
            bidPrice = amount * uint(getChainlinkFeedLatestPrice(address(0)));
        }
        uint startPriceValue = uint(bidAuction.startPrice * uint(getChainlinkFeedLatestPrice(_tokenAddress)));
        uint highestBidValue = uint(bidAuction.highestBidAmount * uint(getChainlinkFeedLatestPrice(_tokenAddress)));
        require(bidPrice>=startPriceValue && bidPrice > highestBidValue,"bid must be higher than the current auction hight bid");
        if (_tokenAddress !=address(0)){
            IERC20 currentErc20 = IERC20(_tokenAddress);
            //如果满足上面出价条件，则进行资产转移到合约
            currentErc20.transferFrom(msg.sender,address(this),amount);
        }

 
        //退还上一个高价的钱给回出价者
        if(bidAuction.highestBidAmount>0){
            if(bidAuction.tokenAddress == address(0)){
                //退还ETH
                payable(bidAuction.highestBidderAddr).transfer(bidAuction.highestBidAmount);
            }else{
                IERC20 preErc20 = IERC20(bidAuction.highestBidderAddr);
                //退还ERC20
                preErc20.transfer(bidAuction.highestBidderAddr,bidAuction.highestBidAmount);
            }
        }

        //更新当前最新出价到拍卖
        bidAuction.highestBidAmount = amount;
        bidAuction.highestBidderAddr = msg.sender;
        bidAuction.tokenAddress = _tokenAddress;


    }
    //将合约中的NFT转给个人并记录转账
    function approveDoneStartTransferToEOA(address nftAddress,address to,uint256 tokenId) internal returns (bool) {
        require(
            IERC721(nftAddress).getApproved(tokenId) == msg.sender,
            "caller not approved"
        );
        IERC721(nftAddress).safeTransferFrom(address(this),to,tokenId);
        emit NFTTransferred(nftAddress, address(this), to, tokenId);
        return true;
    }
    //结束拍卖 :拍卖结束后，NFT 转移给出价最高者，资金转移给卖家。
    function endableAuction(address _nftAddress,uint256 _auctionId) external payable{
        Auction storage endAuction = auctions[_auctionId];
        endAuction.ended = true;
        require(_nftAddress!=address(0),"nft address is not valid");
        IERC721 nft = IERC721(_nftAddress);
        //对转出到最高者进行授权
        nft.approve(address(this),endAuction.tokenId);
        //发起转账
        approveDoneStartTransferToEOA(_nftAddress, endAuction.highestBidderAddr, endAuction.tokenId);
        //资金转移给卖家
        if (endAuction.tokenAddress!=address(0)){
            //转移ERC20
            //授权ERC20权限给当前合约进行转账
            IERC20 erc20 = IERC20(endAuction.tokenAddress);
            erc20.approve(address(this),endAuction.highestBidAmount);
            erc20.transferFrom(address(this),endAuction.highestBidderAddr,endAuction.highestBidAmount);
        }else{
            //转移以太币
            payable(endAuction.highestBidderAddr).transfer(endAuction.highestBidAmount);
        }
    }
    
    //实现合约接收ERC721 nft
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        emit ReceivedERC721(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }
    //只有合约所有者可以升级
    function _authorizeUpgrade(address) internal view override {
        require(admin==msg.sender,"function not allow");
    }
    //检查馈送情况
    function checkLatestprice(address tokenAddress,uint256 amount) external{
        console.log(uint(getChainlinkFeedLatestPrice(tokenAddress)));
        uint256 bidPrice = amount * uint(getChainlinkFeedLatestPrice(tokenAddress));
        emit CheckLatestprice(tokenAddress,amount,bidPrice);
    }
    // 拍卖V2升级内容
    function testHello() public pure returns(string memory){
        return "Hello v2 Auction TO DO LIST";
    }
}

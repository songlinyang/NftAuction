pragma solidity ^0.8;

// 定义一个接口 拍卖接口
interface ISaleNftAuction {
    function initialize(address _initOwner) external;
    //设置价格数据馈送源
    function setAuctionPriceFeeds(address tokenAddress,address _priceETHFeed) external;

    //支持实时价格馈送
    function getChainlinkFeedLatestPrice(address tokenAddress) external view returns(int);

    //创建拍卖
    function createAuctionSale(uint256 _duration,uint256 _startPrice,address _nftAddrss,uint256 _tokenId) external returns(bool);

    //下架拍卖
    function disableAuctionSaleOnlyOne(bool endable,uint256 _tokenId) external;

    //出价：允许用户以ERC20或以太坊出价
    function buyerBid(uint256 _auctionId,uint256 amount,address _tokenAddress) external payable;

    //结束拍卖
    function endableAuction(address _nftAddress,uint256 _auctionId) external payable;

    //检查馈送情况
    // function checkLatestprice(address tokenAddress,uint256 amount) external;

}

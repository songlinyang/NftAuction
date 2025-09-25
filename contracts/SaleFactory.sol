pragma solidity ^0.8;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./SaleNftAuction.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ERC721/MyNFT.sol";
import "hardhat/console.sol";

contract SaleFactory is Initializable,UUPSUpgradeable{

    //可合约升级
    address public admin;  //权限管理地址
    uint public auctionCount; //拍卖数量
    mapping(uint => address) public auctions; // auctionId => auction contract
    function initialize() public initializer {
        admin = msg.sender;
        auctionCount = 0;
    }
    event AuctionCreated(uint256 _duration,uint256 _startPrice,address _AuctionAddress,uint256 _tokenId,address owner);

//     工厂模式：
// 使用类似于 Uniswap V2 的工厂模式，管理每场拍卖。
// 工厂合约负责创建和管理拍卖合约实例。
    /**
        1、创建拍卖
        2、喂价类型
        3、NFT创建
     */
    // function createAuction(uint256 _duration,uint256 _startPrice,address _nftAddrss,uint256 _tokenId) external {
    //     require(admin==msg.sender,"not allow call");

    // }
    //创建拍卖
    // 工厂只负责部署新拍卖合约，并返回地址
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _duration,
        uint256 _startPrice
        ) external returns (address auctionAddr, uint auctionId) {
        // 部署新的拍卖合约，msg.sender为owner
        SaleNftAuction auction = new SaleNftAuction();
        auction.initialize(msg.sender); // 设置owner为NFT持有者

        auctionId = ++auctionCount;
        auctions[auctionId] = address(auction);

        emit AuctionCreated(_duration,_startPrice, address(auction),auctionId, msg.sender);
    }
    //获取新拍卖合约地址和ID
    function getAuctionAddress(uint  auctionId) external view returns(address) {
        return auctions[auctionId];
    }
    //只有合约所有者可以升级
    function _authorizeUpgrade(address) internal view override {
    }
    
}
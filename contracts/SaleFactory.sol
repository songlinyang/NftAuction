pragma solidity ^0.8;
import "@openzeppelin/contracts-upgradeable/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./SaleNftAuction.sol";
contract SaleFactory is Initializable,UUPSUpgradeable,Ownable{

    function initialize(address initialOwner) public initializer {
         _transferOwnership(initialOwner);
    }
    //存储可以进行拍卖的代币类型,记录chainLink的合约
    //0 -> ETH 转美元
    //1 -> USDC 转美元
    mapping (uint => address) public chainlinkContract;

    function createFactoryAuction(uint256 auctionID) external {}

    function disableFactoryAuctionByOnlyOne() external {}
}
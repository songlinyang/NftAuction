# NFT Auction Marketplace

基于以太坊的NFT拍卖市场，采用类似Uniswap V2的工厂模式管理拍卖合约。该项目支持ERC721 NFT的创建、拍卖、出价和结算功能，集成了Chainlink价格预言机实现多币种竞价。

## 功能特性

### 🏭 工厂模式
- 采用Uniswap V2风格的工厂合约模式
- 每个拍卖创建独立的合约实例
- 工厂合约统一管理所有拍卖实例

### 🎯 拍卖功能
- **创建拍卖**: NFT持有者可以创建拍卖并设置起拍价、持续时间
- **多币种出价**: 支持ETH和ERC20代币出价（通过Chainlink价格换算）
- **实时价格馈送**: 集成Chainlink预言机实现价格标准化
- **自动退款**: 出价被超越时自动退还前一个最高出价者的资金
- **拍卖结算**: 拍卖结束后自动转移NFT给最高出价者，资金转给卖家

### 🔧 技术特性
- **可升级合约**: 使用UUPS代理模式支持合约升级
- **安全转账**: 实现ERC721接收接口，安全处理NFT转账
- **权限管理**: 基于管理员权限的访问控制
- **事件日志**: 完整的交易事件记录

## 项目结构

```
MyNftSaleMarket/
├── contracts/                    # 智能合约目录
│   ├── ERC721/
│   │   └── MyNFT.sol            # ERC721 NFT合约
│   ├── Impl/
│   │   └── ISaleNftAuction.sol  # 拍卖合约接口
│   ├── libraries/
│   │   ├── MyConcat.sol         # 字符串拼接工具库
│   │   └── NFTUtils.sol         # NFT工具函数
│   ├── SaleFactory.sol          # 工厂合约（主入口）
│   ├── SaleNftAuction.sol       # 拍卖合约V1
│   └── SaleNftAuctionV2.sol     # 拍卖合约V2（可升级版本）
├── deploy/                      # 部署脚本
│   ├── auction/
│   │   ├── 01_auction.js        # 拍卖合约部署脚本
│   │   └── 02_auction.js        # 拍卖合约升级脚本
│   └── factory/
│       └── 01_factory.js        # 工厂合约部署脚本
├── test/                        # 测试文件
│   ├── index.js                 # 主要测试用例
│   └── update.js                # 升级测试用例
├── deployments/                 # 部署记录
│   └── localhost/               # 本地网络部署信息
├── hardhat.config.js            # Hardhat配置
└── package.json                 # 项目依赖
```

## 智能合约说明

### SaleFactory.sol - 工厂合约
**核心功能**: 创建和管理拍卖合约实例

```solidity
主要函数:
- createAuction(): 创建新的拍卖合约实例
- getAuctionAddress(): 根据ID获取拍卖合约地址
- initialize(): 初始化工厂合约
```

### SaleNftAuction.sol - 拍卖合约
**核心功能**: 处理具体的拍卖逻辑

```solidity
主要函数:
- createAuctionSale(): 创建拍卖并转移NFT到合约
- buyerBid(): 用户出价功能
- endableAuction(): 结束拍卖并结算
- setAuctionPriceFeeds(): 设置价格预言机
- getChainlinkFeedLatestPrice(): 获取最新价格
```

### MyNFT.sol - ERC721 NFT合约
**核心功能**: 创建和管理NFT资产

```solidity
主要函数:
- awardItem(): 铸造新的NFT
- safeTransferFrom(): 安全的NFT转移
```

### ISaleNftAuction.sol - 接口定义
定义拍卖合约的标准接口，确保合约间的兼容性。

## 部署步骤

### 环境要求
- Node.js (版本 16+)
- npm 或 yarn
- Hardhat 开发环境

### 1. 安装依赖
```bash
npm install
```

### 2. 配置网络
在 `hardhat.config.js` 中配置目标网络：
结合infura进行测试网关联
```javascript
module.exports = {
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    // 添加其他网络配置...
    sepolia: {
      url:`https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts:[process.env.PK]
    }
  }
};
```

### 3. 编译合约
```bash
npx hardhat compile
```

### 4. 部署合约

#### 方式一：使用部署脚本
```bash
# 部署拍卖合约
npx hardhat deploy --tags deploySaleNftAuction

# 部署工厂合约
npx hardhat deploy --tags deployAuctionFactory
```

#### 方式二：手动部署
```bash
# 启动本地节点
npx hardhat node

# 在新终端中部署
npx hardhat run deploy/auction/01_auction.js --network localhost
npx hardhat run deploy/factory/01_factory.js --network localhost

# 在sepolia测试网部署
px hardhat run deploy/auction/01_auction.js --network sepolia
npx hardhat run deploy/factory/01_factory.js --network sepolia
```

### 5. 测试合约
```bash
# 运行所有测试
npx hardhat test

# 运行测试并显示gas消耗
REPORT_GAS=true npx hardhat test

# 运行特定测试文件
npx hardhat test test/index.js
```

## 使用流程

### 1. 创建NFT
```javascript
const MyNFT = await ethers.getContractFactory("MyNFT");
const myNFT = await MyNFT.deploy("MyNFT", "MNFT");
await myNFT.awardItem(ownerAddress, tokenURI);
```

### 2. 创建拍卖
```javascript
// 通过工厂创建拍卖
const factory = await ethers.getContractAt("SaleFactory", factoryAddress);
const tx = await factory.createAuction(nftAddress, tokenId, duration, startPrice);
const receipt = await tx.wait();

// 获取拍卖合约地址
const auctionAddress = await factory.getAuctionAddress(auctionId);
const auction = await ethers.getContractAt("SaleNftAuction", auctionAddress);

// 授权并创建拍卖
await myNFT.approve(auctionAddress, tokenId);
await auction.createAuctionSale(duration, startPrice, nftAddress, tokenId);
```

### 3. 设置价格预言机
```javascript
// 设置ETH价格预言机
await auction.setAuctionPriceFeeds(ethers.ZeroAddress, chainlinkFeedAddress);
```

### 4. 参与拍卖
```javascript
// 使用ETH出价
await auction.buyerBid(auctionId, bidAmount, ethers.ZeroAddress, { value: bidAmount });

// 使用ERC20出价（需要先授权）
await auction.buyerBid(auctionId, bidAmount, erc20TokenAddress);
```

### 5. 结束拍卖
```javascript
// 拍卖结束后结算
await auction.endableAuction(nftAddress, auctionId);
```

## 测试用例

项目包含完整的测试覆盖：

- ✅ ERC721合约部署测试
- ✅ 拍卖合约创建测试
- ✅ 价格预言机设置测试
- ✅ 出价功能测试
- ✅ 拍卖结算测试

运行测试：
```bash
npx hardhat test
```

## 技术栈

- **区块链开发**: Hardhat, Ethers.js
- **智能合约**: Solidity 0.8.x
- **代币标准**: ERC721, ERC20
- **预言机**: Chainlink Price Feeds
- **代理模式**: UUPS可升级合约
- **测试框架**: Mocha, Chai

## 安全考虑

- 使用OpenZeppelin合约库的安全实现
- 实现重入攻击防护
- 严格的权限控制
- 完整的输入验证
- 事件日志记录所有关键操作

## 开发指南

### 添加新功能
1. 在 `contracts/` 目录下创建新合约
2. 编写相应的测试用例
3. 更新部署脚本（如需要）
4. 运行测试确保功能正常

### 合约升级
项目支持UUPS代理模式升级：
```bash
# 部署新版本
npx hardhat run deploy/auction/02_auction.js --network localhost
```

## 故障排除

### 常见问题
1. **编译错误**: 检查Solidity版本兼容性
2. **部署失败**: 确认网络配置和gas设置
3. **测试失败**: 检查测试环境配置

### 获取帮助
- 查看Hardhat文档: https://hardhat.org/docs
- 检查合约错误日志
- 运行 `npx hardhat help` 获取命令帮助

## 贡献指南

欢迎提交Issue和Pull Request来改进项目。

## 许可证

MIT License

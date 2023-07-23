// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./lastvault.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/* Price feeds addresses
0xf9680d99d6c9589e2a93a78a04a279e509205945 ETH/USD
0xc907e116054ad103354f2d350fd2514433d57f6f BTC/USD 0xc907e116054ad103354f2d350fd2514433d57f6f
0x4746dec9e833a82ec7c2c1356372ccf2cfcd2f3d DAI/USD
0xab594600376ec9fd91f8e885dadf0ce036862de0 MATIC/USD 0xab594600376ec9fd91f8e885dadf0ce036862de0
0x0a6513e40db6eb1b165753ad52e80663aea50545 USDT/USD
0xd9ffdb71ebe7496cc440152d43986aae0ab76665 LINK/USD
0x82a6c4af830caa6c97bb504425f6a66165c2c26e BNB/USD 0x82a6c4af830caa6c97bb504425f6a66165c2c26e
0xdf0fb4e4f928d2dcb76f438575fdd8682386e13c UNI/USD 0xdf0fb4e4f928d2dcb76f438575fdd8682386e13c
0x443c5116cdf663eb387e72c688d276e702135c87 1INCH/USD 0x443c5116cdf663eb387e72c688d276e702135c87
0x72484b12719e23115761d5da1646945632979bb6 AAVE/USD 0x72484b12719e23115761d5da1646945632979bb6
*/

//[10, 10, 10, 10, 10, 10, 10, 10, 10, 10]

contract C10Token is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("C10index", "C10") {}

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function burnTokens(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }
}

contract C10ETF is C10Token, C10Vault {
    address public constant routerAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    ISwapRouter public immutable swapRouter = ISwapRouter(routerAddress);
    using SafeMath for uint256;

    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    IERC20 public usdcToken = IERC20(USDC);

    C10Vault public vault;//CONTRACT DU VAULT
    

    AggregatorV3Interface[] public priceFeeds;

    //Asset public assets;
    //Assets structure array
    Asset[5] public assets;
    mapping (address => uint256) public tokenBalances;
    
    //address public tokenAddresses;
    address[5] public tokenAddresses;
    uint256[5] public decimal;
    uint256 public i = 0;
    uint256 public j = 0;
    uint256 public AUM_In_Usd;
    uint256 public C10_Supply;
    uint256 public C10_Price;
    uint256 public Pool_Value;
    uint256 public tokenBalance;
    uint256 public tokenPrice;
    uint24 public poolFee = 3000;
    //uint256 public Proportion;
    uint256[5] public Proportion;
    event transaction_success(uint256 value);


    function setVaultAddress(address _vault) public onlyOwner {
        vault = C10Vault(_vault);
    }

    function changeVaultOwner(address _vaultOwner) public onlyOwner {
        vault.setC10ContractAsOwner(_vaultOwner);
    }

    function getTotalSupply() public view returns (uint256) {
    return totalSupply();
    }
    function getc10Price()public view returns(uint256){
        return AUM_In_Usd/ totalSupply();
    }

    function getTVL()public view returns(uint256){
        return AUM_In_Usd;
    }

    function mint_single(uint amount) public {
         mint(amount);
    }

    struct Asset 
    {
        uint256 price;
    }

    //uint256 public decimal = [18];
    constructor() 
    {
    decimal[0] = 18;
    decimal[1] = 18;
    decimal[2] = 18;
    decimal[3] = 18;
    decimal[4] = 18;
    Proportion[0] = 20;
    Proportion[1] = 20;
    Proportion[2] = 20;
    Proportion[3] = 20;
    Proportion[4] = 20;
    tokenAddresses[0] = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;//WETH
    tokenAddresses[1] = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;//LINK
    tokenAddresses[2] = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;//BTC
    tokenAddresses[3] = 0x0000000000000000000000000000000000001010;//Matic
    tokenAddresses[4] = 0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3;//BNB
    //priceFeeds.push(AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945));
    priceFeeds = new AggregatorV3Interface[](2);
    priceFeeds[0] = AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945);//weth
    priceFeeds[1] = AggregatorV3Interface(0xd9FFdb71EbE7496cC440152d43986Aae0AB76665);//link
    priceFeeds[2] = AggregatorV3Interface(0xc907e116054ad103354f2d350fd2514433d57f6f);//btc
    priceFeeds[3] = AggregatorV3Interface(0xab594600376ec9fd91f8e885dadf0ce036862de0);//matic
    priceFeeds[4] = AggregatorV3Interface(0x82a6c4af830caa6c97bb504425f6a66165c2c26e);//bnb
    }

    function sell_swap(address recipient, uint256 _amountIn) public returns (uint256){
    IERC20 token = IERC20(tokenAddresses[i]);
    token.approve(address(swapRouter), _amountIn);
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        .ExactInputSingleParams({
            tokenIn: tokenAddresses[i],
            tokenOut: USDC,
            fee: poolFee,
            recipient: recipient,
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
       uint256 amountOut = swapRouter.exactInputSingle(params);
       return (amountOut);
    }

    function updateAssetValues() public 
    {
        for (i = 0; i < priceFeeds.length; i++) 
        {
            (, int256 price, , , ) = priceFeeds[i].latestRoundData();
            assets[i].price = uint256(price);
        }
    }


    function _updateTokenBalanceWORK() public{

        for (i = 0; i < tokenAddresses.length; i++){
            uint256 nextBalance = IERC20(tokenAddresses[i]).balanceOf(address(vault));//with 18 decimals
            tokenBalances[tokenAddresses[i]] = nextBalance;
        }
    }


function _updatePoolValueWORK() public returns (uint256) {
    Pool_Value = 0; 

    _updateTokenBalanceWORK(); 
    updateAssetValues();
    for (i = 0; i < tokenAddresses.length; i++) {
        tokenBalance = (tokenBalances[tokenAddresses[i]]);
        tokenPrice = (assets[i].price / 1e8);
        Pool_Value = Pool_Value.add(tokenBalance.mul(tokenPrice));
    }

    return Pool_Value;
}

        function buy_swap(uint256 amountIn) public returns (uint256 amountOut)
     {
        usdcToken.approve(address(swapRouter), amountIn);
         ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
             .ExactInputSingleParams({
                 tokenIn: USDC,
                 tokenOut: tokenAddresses[i],
                 fee: poolFee,
                 recipient: address(vault),
                 deadline: block.timestamp,
                 amountIn: amountIn,
                 amountOutMinimum: 0,
                 sqrtPriceLimitX96: 0
             });
         amountOut = swapRouter.exactInputSingle(params);     
     }

     function BuyETF(uint256 usdcAmount) public  {    
         require(usdcToken.allowance(msg.sender, address(this)) >= usdcAmount, "Error");
         require(usdcToken.transferFrom(msg.sender, address(this), usdcAmount), "Error.");
         AUM_In_Usd = _updatePoolValueWORK();
         C10_Supply = getTotalSupply();
         C10_Supply = C10_Supply / 1e5;
         if (AUM_In_Usd == 0 && C10_Supply == 0){
              C10_Supply = 1e18;
              AUM_In_Usd = 1e21;
         }
         C10_Price = AUM_In_Usd / C10_Supply;//821 car ca devient un e16
         for (i = 0; i < assets.length; i++){
             buy_swap(Proportion[i]*usdcAmount /100);
         }
         AUM_In_Usd = _updatePoolValueWORK();
         usdcAmount = usdcAmount * 1e17;
         mint(usdcAmount / C10_Price);
     }

     function SellETF(uint256 amount) public { 
         address recipient = msg.sender;
         AUM_In_Usd = _updatePoolValueWORK();
         C10_Supply = getTotalSupply();
         C10_Supply = C10_Supply / 1e5;
         C10_Price = AUM_In_Usd / C10_Supply;//821 car ca devient un e16
        for (i = 0; i < assets.length; i++) {
            uint256 amountToWithdraw = (amount * Proportion[i] / 100) / assets[i].price / 1e9;
            vault.withdraw(tokenAddresses[i], amountToWithdraw);
        }
         i = 0;
        for (j = 0; j < assets.length; j++) {
            uint256 amountToSwap = (amount * Proportion[j] / 100) / assets[j].price / 1e9;
            sell_swap(recipient,amountToSwap);
        }
         amount =  amount / 1e12;
         AUM_In_Usd = _updatePoolValueWORK();
         burn(amount/C10_Price);
     }
 }
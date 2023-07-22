/*
  .oooooo.     .o    .oooo.   ooooo ooooo      ooo oooooooooo.   oooooooooooo ooooooo  ooooo 
 d8P'  `Y8b  o888   d8P'`Y8b  `888' `888b.     `8' `888'   `Y8b  `888'     `8  `8888    d8'  
888           888  888    888  888   8 `88b.    8   888      888  888            Y888..8P    
888           888  888    888  888   8   `88b.  8   888      888  888oooo8        `8888'     
888           888  888    888  888   8     `88b.8   888      888  888    "       .8PY888.    
`88b    ooo   888  `88b  d88'  888   8       `888   888     d88'  888       o   d8'  `888b   
 `Y8bood8P'  o888o  `Y8bd8P'  o888o o8o        `8  o888bood8P'   o888ooooood8 o888o  o88888o 
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract C10Vault is Ownable {

    address public C10Contract;

    function setC10ContractAsOwner(address _C10Contract) external onlyOwner {
        C10Contract = _C10Contract;
        transferOwnership(_C10Contract);
    }

    function withdraw(address _tokenAddress, uint256 _amount) external onlyOwner {
    	IERC20 token = IERC20(_tokenAddress);
    	require(_amount > 0, "Amount must be greater than zero");
    	require(token.balanceOf(address(this)) >= _amount, "Insufficient balance");
    	token.transfer(msg.sender, _amount);
     }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IRouter {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IERC20 {
    function transferFrom(address from, address to, uint value) external;

    function approve(address to, uint value) external returns (bool);
}

contract Swap_Example {

    address private router; // Swap Router Address
    address private wavaxAddress; // Address of WAVAX

    constructor(address _router, address _wavaxAddress){
        router = _router;
        wavaxAddress = _wavaxAddress;
    }

    receive() external payable {}

    function swap(address from, uint256 amountOutMin, address[] calldata path, uint256 amountIn, address tokenIn, uint256 deadline, uint256 gasEstimate) external {
        // We transfer the wavax from the user (msg.sender) to this contract.
        IERC20(tokenIn).transferFrom(from, address(this), amountIn);
        // We approve the router as a spender for our Wavax.
        IERC20(tokenIn).approve(router, amountIn);
        // We do the swap using the router.
        IRouter(router).swapExactTokensForTokens(amountIn, amountOutMin, path, from, deadline);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRouter {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IERC20 {
    function transferFrom(address from, address to, uint value) external;

    function approve(address to, uint value) external returns (bool);
}

contract Swap_Example {

    address private router; // Swap Router Address

    constructor(address _router, address _wavaxAddress){
        router = _router;
    }

    receive() external payable {}

    // For this function to be used, the amountIn of tokenIn needs to already be approved to be spent by the address of this contract, or else it won't work
    function swap(uint256 amountOutMin, address[] calldata path, uint256 amountIn, address tokenIn, uint256 deadline) external {
        // We transfer the tokenIn from the user (msg.sender) to this contract.
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        // We approve the router as a spender for our Wavax.
        IERC20(tokenIn).approve(router, amountIn);
        // We do the swap using the router.
        IRouter(router).swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender, deadline);
    }
}
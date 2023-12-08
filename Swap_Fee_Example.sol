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

    function withdraw(uint wad) external; 

    function balanceOf(address account) external view returns (uint256);
}

contract Swapper is Ownable, ReentrancyGuard {

    address private router; // Swap Router Address
    address private wavaxAddress; // Address of WAVAX
    address public _owner; // Owner wallet
    address payable feeRecipient; // Fee recipient
    
    constructor(address initialOwner, address _router, address _wavaxAddress, address payable _feeRecipient) Ownable(initialOwner) {
        _owner = initialOwner;
        router = _router;
        wavaxAddress = _wavaxAddress;
        feeRecipient = _feeRecipient;
    }

    receive() external payable {}

    // If we ever need to change the feeRecipient
    function changeFeeRecipientAddress(address payable _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function swap(address from, uint256 amountOutMin, address[] calldata path, uint256 amountIn, address tokenIn, uint256 deadline) external nonReentrant {
        // We transfer the wavax from the user (msg.sender) to this contract.
        IERC20(tokenIn).transferFrom(from, address(this), amountIn);
        // We approve the router as a spender for our Wavax.
        IERC20(tokenIn).approve(router, amountIn);
        // We calculate the fee and send it to the fee recipient
        uint256 fee = (amountIn * 4 / 1000); // 0.4% + gas fees            
        amountIn -= fee;
        // We do the swap using the router.
        IRouter(router).swapExactTokensForTokens(amountIn, amountOutMin, path, from, deadline);
        // If the tokenIn is not WAVAX, we need to convert it
        if(tokenIn != wavaxAddress) {
            // Convert the fee to WAVAX
            address[] memory tokenPath = new address[](2);
            tokenPath[0] = tokenIn;
            tokenPath[1] = wavaxAddress;
            IERC20(tokenIn).approve(router, fee);
            IRouter(router).swapExactTokensForTokens(fee, amountOutMin, tokenPath, address(this), deadline);
        }
        uint256 wavaxBalance = IERC20(wavaxAddress).balanceOf(address(this));
        // Converts WAVAX to AVAX
        IERC20(wavaxAddress).approve(wavaxAddress, wavaxBalance);
        IERC20(wavaxAddress).withdraw(wavaxBalance);
        // Send AVAX to the feeRecipient
        (bool success, ) = feeRecipient.call{value: wavaxBalance}("");
        require(success, "transaction failed");
    }
}


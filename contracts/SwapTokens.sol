// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SwapToken {
    using SafeERC20 for IERC20;

    struct SwapingOrder {
        address depositor;
        uint256 amountDeposited;
        address depositToken;
        address requestedToken;
        uint256 amountRequested;
        bool isSuccessful;
    }

    // Order ID => Swaping Order
    mapping(uint256 => SwapingOrder) public swapOrders;
    uint256 public orderCount;

    // Events
    event OrderCreated(uint256 orderId, address indexed depositor, address depositToken, uint256 amountDeposited, address indexed requestedToken, uint256 amountRequested);
    event OrderFulfilled(uint256 orderId, address indexed fulfiller);
    event OrderCanceled(uint256 orderId);

    function createSwapingOrder ( address _depositToken, uint256 _amountDeposited, address _requestedToken, uint256 _amountRequested) external {
        require(_amountDeposited > 0, "Amount deposited should be greater than 0");
        require(_amountRequested > 0, "Amount requested should be greater than 0");

        IERC20(_depositToken).safeTransferFrom(msg.sender, address(this), _amountDeposited);

        swapOrders[orderCount] = SwapingOrder(msg.sender, _amountDeposited, _depositToken, _requestedToken, _amountRequested, false);

        emit OrderCreated(orderCount, msg.sender, _depositToken, _amountDeposited, _requestedToken, _amountRequested);
    }

    function fulfillSwapOrder(uint256 _orderId) external {
        SwapingOrder storage order = swapOrders[_orderId];
        require(!order.isSuccessful, "Order has already been fulfilled");
        require(order.depositor != msg.sender, "You can't fulfill your own order");

        // check if fulfiller has enough tokens
        require(IERC20(order.requestedToken).balanceOf(msg.sender) >= order.amountRequested, "You don't have enough tokens to fulfill this order");

        // Transfering the token from the fulfiller to the one deposited
        IERC20(order.requestedToken).safeTransferFrom(msg.sender, order.depositor, order.amountRequested);

        // Transfer the deposit tokens from the contract to the fulfiller
        IERC20(order.depositToken).safeTransfer(msg.sender, order.amountDeposited);

        // Mark the order as fulfilled
        order.isSuccessful = true;

        emit OrderFulfilled(_orderId, msg.sender);
    }

    function cancelSwapOrder(uint256 _orderId) external {
        SwapingOrder storage order = swapOrders[_orderId];
        require(order.depositor == msg.sender, "Only the depositor can cancel the order");
        require(!order.isSuccessful, "Order has already been fulfilled");

        // Transfer the deposit tokens back to the depositor
        IERC20(order.depositToken).safeTransfer(order.depositor, order.amountDeposited);

        // Remove the order from the mapping
        delete swapOrders[_orderId];

        emit OrderCanceled(_orderId);
    }

    // Get the order details
    function getOrder(uint256 _orderId) external view returns (SwapingOrder memory) {
        return swapOrders[_orderId];
    }
  
}

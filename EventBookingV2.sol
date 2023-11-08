// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
interface IERC20_USDT {
    function transferFrom(address from, address to, uint value) external;
}

contract EventBooking {

    struct Booking {
        bytes32 bookingId;
        uint256 eventId;
        uint256 amount;
    }

    IERC20 public token;
    address payable public admin;
    address public deployer;
    mapping(address => Booking[]) public bookings;

    constructor(address _token, address payable _admin) {
        token = IERC20(_token);
        admin = _admin;
        deployer = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer can call this function");
        _;
    }
    function bookEventByAdmin(uint256 _eventId, uint256 _amount, address _user, address _paymentToken) external onlyDeployer {
        if (_paymentToken == 0xdAC17F958D2ee523a2206206994597C13D831ec7) {
            IERC20_USDT usdtToken = IERC20_USDT(_paymentToken);
            usdtToken.transferFrom(_user, admin, _amount);
        } else {
            IERC20 paymentToken = IERC20(_paymentToken);
            require(paymentToken.transferFrom(_user, admin, _amount), "Failed to transfer payment tokens");
        }

        // Generate a unique booking ID using keccak256
        bytes32 uniqueBookingId = keccak256(abi.encodePacked(msg.sender, _eventId, block.timestamp));

        Booking memory newBooking = Booking({
            bookingId: uniqueBookingId,
            eventId: _eventId,
            amount: _amount
        });

        bookings[_user].push(newBooking);
    }

    function bookEvent(uint256 _eventId, uint256 _amount) external {
        // Ensure the tokens are transferred from the user to the contract
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer from user failed");

        // Generate a unique booking ID using keccak256
        bytes32 uniqueBookingId = keccak256(abi.encodePacked(msg.sender, _eventId, block.timestamp));

        Booking memory newBooking = Booking({
            bookingId: uniqueBookingId,
            eventId: _eventId,
            amount: _amount
        });

        bookings[msg.sender].push(newBooking);
    
        require(token.transfer(admin, _amount), "Transfer to admin failed");
    }
    function bookEventWithETH(uint256 _eventId, uint256 _amount) external payable {
        require(msg.value > 0, "No ETH supplied");

        // Generate a unique booking ID using keccak256
        bytes32 uniqueBookingId = keccak256(abi.encodePacked(msg.sender, _eventId, block.timestamp));

        Booking memory newBooking = Booking({
            bookingId: uniqueBookingId,
            eventId: _eventId,
            amount: _amount
        });

        bookings[msg.sender].push(newBooking);
        
        admin.transfer(msg.value);
    }

    function getBookings(address _user) external view returns (Booking[] memory) {
        return bookings[_user];
    }
    
    function withdrawTokens() external onlyAdmin {
        uint256 contractBalance = token.balanceOf(address(this));
        require(token.transfer(admin, contractBalance), "Transfer to admin failed");
    }

    function transferOwnership(address payable newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "New admin address cannot be zero address");
        admin = newAdmin;
    }
}
// SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.0;
// upgrade solidity version so Custom Errors can be used
pragma solidity 0.8.18;

import "./Ownable.sol";

/*contract Constants {
    uint256 public tradeFlag = 1;
    uint256 public basicFlag = 0;
    uint256 public dividendFlag = 1;
}*/

contract GasContract is Ownable {
    /*
    remove Const contract and consolidate into one
    make some variables into uint8
    remove public from variable that are not called
    basicFlag is never used, so remove it
    */
    // isReady is not used, so remove it 
    // bool public isReady = false;

    uint8 tradeFlag = 1;
    uint8 dividendFlag = 1;

    // tradePercent has no method of change, so make a constant
    uint8 constant tradePercent = 12;
    uint256 paymentCounter = 0;
    uint256 public tradeMode = 0;
    // make totalSupply immutable since it cannot be updated
    uint256 public immutable totalSupply; // cannot be updated

    address contractOwner;
    address[5] public administrators;
    
    mapping(address => uint256) public balances;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }
    PaymentType constant defaultPayment = PaymentType.Unknown;

    History[] public paymentHistory; // when a payment was updated

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }

    struct History {
        uint256 lastUpdate;
        address updatedBy;
        uint256 blockNumber;
    }
    // remove wasLastOdd variable and logic in later function
    // uint256 wasLastOdd = 1;
    // mapping(address => uint256) public isOddWhitelistUser;
    /*
    remove unused ImportantStruct
    
    struct ImportantStruct {
        uint256 valueA; // max 3 digits
        uint256 bigValue;
        uint256 valueB; // max 3 digits
    }
    */

    // remove unused ImportantStruct
    // mapping(address => ImportantStruct) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);

    /*
    add Custom Error with revert
    slim down logic
    */
    error CallerNotAdminOrOwner();

    modifier onlyAdminOrOwner() {
        if(!checkForAdmin(msg.sender) || contractOwner != msg.sender) {
            revert CallerNotAdminOrOwner();
        }
        _;
    }

    /*modifier onlyAdminOrOwner() {
        address senderOfTx = msg.sender;
        if (checkForAdmin(senderOfTx)) {
            require(
                checkForAdmin(senderOfTx),
                "Gas Contract Only Admin Check-  Caller not admin"
            );
            _;
        } else if (senderOfTx == contractOwner) {
            _;
        } else {
            revert(
                "Error in Gas contract - onlyAdminOrOwner modifier : revert happened because the originator of the transaction was not the admin, and furthermore he wasn't the owner of the contract, so he cannot run this function"
            );
        }
    }*/

    error InvalidWhiteListTier();
    error UserNotWhiteListed();
    error CanOnlyCheckOwnAddress();

    modifier checkIfWhiteListed(address sender) {
        if (sender != msg.sender) {
            revert CanOnlyCheckOwnAddress();
        }
        uint256 usersTier = whitelist[sender];
        if (usersTier < 1) {
            revert UserNotWhiteListed();
        } else if (usersTier > 3) {
            revert InvalidWhiteListTier();
        }
        _;
        /*address senderOfTx = msg.sender;
        require(
            senderOfTx == sender,
            "Gas Contract CheckIfWhiteListed modifier : revert happened because the originator of the transaction was not the sender"
        );
        uint256 usersTier = whitelist[senderOfTx];
        require(
            usersTier > 0,
            "Gas Contract CheckIfWhiteListed modifier : revert happened because the user is not whitelisted"
        );
        require(
            usersTier < 4,
            "Gas Contract CheckIfWhiteListed modifier : revert happened because the user's tier is incorrect, it cannot be over 4 as the only tier we have are: 1, 2, 3; therfore 4 is an invalid tier for the whitlist of this contract. make sure whitlist tiers were set correctly"
        );*/
    }

    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        /*
        consolidate if/then logic
        */
        for (uint256 ii = 0; ii < 5; ii++) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == contractOwner) {
                    balances[contractOwner] = totalSupply;
                    emit supplyChanged(_admins[ii], totalSupply);
                } else {
                    balances[_admins[ii]] = 0;
                    emit supplyChanged(_admins[ii], 0);
                }
            }
        }
    }

    /*
    paymentHistory is public, so it already has a built-in getter function

    function getPaymentHistory()
        public
        payable
        returns (History[] memory paymentHistory_)
    {
        return paymentHistory;
    */

    /*
    add a break statement if admin address is a match
    remove return statement and use built-in
    */
    function checkForAdmin(address _user) public view returns (bool admin_) {
        admin_ = false;
        for (uint256 ii = 0; ii < 5; ii++) {
            if (administrators[ii] == _user) {
                admin_ = true;
                break;
            }
        }
        /*bool admin = false;
        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                admin = true;
            }
        }
        return admin;*/
    }

    /*
    remove local variable and use the auto-return
    */
    function balanceOf(address _user) public view returns (uint256 balance_) {
        balance_ = balances[_user];
        /*uint256 balance = balances[_user];
        return balance;*/
    }

    /*
    remove local variable
    remove return statement and use auto-return of function
    */
    function getTradingMode() public view returns (bool mode_) {
        /*bool mode = false;
        if (tradeFlag == 1 || dividendFlag == 1) {
            mode = true;
        } else {
            mode = false;
        }
        return mode;*/
        mode_ = false;
        if (tradeFlag == 1 || dividendFlag == 1) {
            mode_ = true;
        }
    }

    function addHistory(address _updateAddress/*, bool _tradeMode*/) public
        /* the return values are not used, so comment them out
        returns (bool status_, bool tradeMode_)
        */
    {
        History memory history;
        history.blockNumber = block.number;
        history.lastUpdate = block.timestamp;
        history.updatedBy = _updateAddress;
        paymentHistory.push(history);
        /*
        bool[] memory status = new bool[](tradePercent);
        for (uint256 i = 0; i < tradePercent; i++) {
            status[i] = true;
        }
        return ((status[0] == true), _tradeMode);
        */
    }

    /*
    add a Custom Error and revert statement
    remove the return statement as it will already return payments_ variable
    */
    error NeedValidNonZeroAddress();

    function getPayments(address _user)
        public view returns (Payment[] memory payments_) {
        /*require(
            _user != address(0),
            "Gas Contract - getPayments function - User must have a valid non zero address"
        );
        return payments[_user];*/
        if (_user == address(0)) {
            revert NeedValidNonZeroAddress();
        }
        payments_ = payments[_user];
    }

    /*
    add 2 Custom Error messages with revert statements
    remove status as it is never used
    */
    error SenderInsufficientBalance();
    error RecipientName8CharacterLimit();

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public /*returns (bool status_)*/ {
        // address senderOfTx = msg.sender;
        /*require(
            balances[senderOfTx] >= _amount,
            "Gas Contract - Transfer function - Sender has insufficient Balance"
        );
        require(
            bytes(_name).length < 9,
            "Gas Contract - Transfer function -  The recipient name is too long, there is a max length of 8 characters"
        );*/
        if (balances[msg.sender] < _amount) {
            revert SenderInsufficientBalance();
        }
        if (bytes(_name).length > 8) {
            revert RecipientName8CharacterLimit();
        }
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        Payment memory payment;
        payment.admin = address(0);
        payment.adminUpdated = false;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = _name;
        payment.paymentID = ++paymentCounter;
        payments[msg.sender].push(payment);
        /*
        status is never used for anything, so comment out

        bool[] memory status = new bool[](tradePercent);
        for (uint256 i = 0; i < tradePercent; i++) {
            status[i] = true;
        }
        return (status[0] == true);
        */
    }

    error IDMustBeGreaterThan0();
    error AmountMustBeGreaterThan0();

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) public onlyAdminOrOwner {
        if (_ID <= 0) {
            revert IDMustBeGreaterThan0();
        }
        if (_amount <= 0) {
            revert AmountMustBeGreaterThan0();
        }
        if (_user == address(0)) {
            revert NeedValidNonZeroAddress();
        }
        /*require(
            _ID > 0,
            "Gas Contract - Update Payment function - ID must be greater than 0"
        );
        require(
            _amount > 0,
            "Gas Contract - Update Payment function - Amount must be greater than 0"
        );
        require(
            _user != address(0),
            "Gas Contract - Update Payment function - Administrator must have a valid non zero address"
        );

        address senderOfTx = msg.sender;
        */

        for (uint256 ii = 0; ii < payments[_user].length; ii++) {
            if (payments[_user][ii].paymentID == _ID) {
                payments[_user][ii].adminUpdated = true;
                payments[_user][ii].admin = _user;
                payments[_user][ii].paymentType = _type;
                payments[_user][ii].amount = _amount;
                // tradingMode is not used to comment out
                //bool tradingMode = getTradingMode();
                addHistory(_user/*, tradingMode*/);
                emit PaymentUpdated(
                    msg.sender,
                    _ID,
                    _amount,
                    payments[_user][ii].recipientName
                );
            }
        }
    }

    /*
    add Custom Error
    reduce logic and remove local variable
    */
    error TierLevelGreaterThan255();

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public onlyAdminOrOwner {
        if (_tier > 255) {
            revert TierLevelGreaterThan255();
        }
        if (_tier >= 3) {
            whitelist[_userAddrs] = 3;
        } else {
            whitelist[_userAddrs] = _tier;
        }
        emit AddedToWhitelist(_userAddrs, _tier);
        /*require(
            _tier < 255,
            "Gas Contract - addToWhitelist function -  tier level should not be greater than 255"
        );
        whitelist[_userAddrs] = _tier;
        if (_tier >= 3) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 3;
        } else if (_tier == 1) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 1;
        } else if (_tier > 0 && _tier < 3) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 2;
        }
        
        // remove section that seems totally unnecessary

        uint256 wasLastAddedOdd = wasLastOdd;
        if (wasLastAddedOdd == 1) {
            wasLastOdd = 0;
            isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
        } else if (wasLastAddedOdd == 0) {
            wasLastOdd = 1;
            isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
        } else {
            revert("Contract hacked, imposible, call help");
        }
        */
    }

    /*
    add one Custom Error and reuse one from an earlier function
    */ 
    error AmountSentMustExceed3();

    function whiteTransfer(
        address _recipient,
        uint256 _amount
        // remove unused ImportantStruct
        // ImportantStruct memory _struct
    ) public checkIfWhiteListed(msg.sender) {
        // remove unnecessary local variable
        // address senderOfTx = msg.sender;

        if (balances[msg.sender] < _amount) {
            revert SenderInsufficientBalance();
        } else if (_amount <= 3) {
            revert AmountSentMustExceed3();
        }
        balances[msg.sender] -= _amount - whitelist[msg.sender];
        balances[_recipient] += _amount - whitelist[msg.sender];
        emit WhiteListTransfer(_recipient);
        /*
        reduce math logic
        
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        balances[msg.sender] += whitelist[msg.sender];
        balances[_recipient] -= whitelist[msg.sender];
        */

        /*
        require(
            balances[msg.sender] >= _amount,
            "Gas Contract - whiteTransfers function - Sender has insufficient Balance"
        );
        require(
            _amount > 3,
            "Gas Contract - whiteTransfers function - amount to send have to be bigger than 3"
        )*/

        /*
        remove unused ImportantStruct

        whiteListStruct[msg.sender] = ImportantStruct(0, 0, 0);
        ImportantStruct storage newImportantStruct = whiteListStruct[msg.sender];
        newImportantStruct.valueA = _struct.valueA;
        newImportantStruct.bigValue = _struct.bigValue;
        newImportantStruct.valueB = _struct.valueB;
        */
    }
}

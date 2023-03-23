// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Crop.sol";
import "./Farmer.sol";
import "./Transporter.sol";
import "./Product.sol";
import "./Processor.sol";
import "./ProductW_D.sol";
import "./Wholesaler.sol";
import "./ProductD_C.sol";
import "./Distributor.sol";
import "./Customer.sol";

//// New supply chain : farmer -> transporter -> processor -> transporter -> whole-saler -> transporter -> distributor -> transporter -> customer/hospital/pharmacy

contract SupplyChain is
    Farmer,
    Transporter,
    Processor,
    Wholesaler,
    Distributor,
    Customer
{
    address public Owner;

    constructor() public {
        Owner = msg.sender;
    }

    modifier onlyOwner() {
        require(Owner == msg.sender);
        _;
    }

    modifier checkUser(address addr) {
        require(addr == msg.sender);
        _;
    }

    enum roles {
        noRole,
        farmer,
        transporter,
        processor,
        wholesaler,
        distributor,
        customer
    }

    //////////////// Events ////////////////////

    event UserRegister(address indexed _address, bytes32 name);
    event buyEvent(
        address buyer,
        address seller,
        address packageAddr,
        bytes32 signature,
        uint256 indexed now
    );
    event respondEvent(
        address buyer,
        address seller,
        address packageAddr,
        bytes32 signature,
        uint256 indexed now
    );
    event sendEvent(
        address seller,
        address buyer,
        address packageAddr,
        bytes32 signature,
        uint256 indexed now
    );
    event receivedEvent(
        address buyer,
        address seller,
        address packageAddr,
        bytes32 signature,
        uint256 indexed now
    );

    /////////////// Users (Only Owner Executable) //////////////////////

    struct userData {
        bytes32 name;
        string[] userLoc;
        roles role;
        address userAddr;
    }

    mapping(address => userData) public userInfo;

    function registerUser(
        bytes32 name,
        string[] memory loc,
        uint256 role,
        address _userAddr
    ) external onlyOwner {
        userInfo[_userAddr].name = name;
        userInfo[_userAddr].userLoc = loc;
        userInfo[_userAddr].role = roles(role);
        userInfo[_userAddr].userAddr = _userAddr;

        emit UserRegister(_userAddr, name);
    }

    function changeUserRole(uint256 _role, address _addr)
        external
        onlyOwner
        returns (string memory)
    {
        userInfo[_addr].role = roles(_role);
        return "Role Updated!";
    }

    function getUserInfo(address _address)
        external
        view
        onlyOwner
        returns (userData memory)
    {
        return userInfo[_address];
    }

    

    /////////////// Farmer //////////////////////

    function farmerCreatesCropPackage(
        bytes32 _description,
        uint256 _quantity,
        address _transporterAddr,
        address _processorAddr
    ) external {
        require(
            userInfo[msg.sender].role == roles.farmer,
            "Role=>Farmer can use this function"
        );

        createCropPackage(
            _description,
            _quantity,
            _transporterAddr,
            _processorAddr
        );
    }

    function farmerGetPackageCount() external view returns (uint256) {
        require(
            userInfo[msg.sender].role == roles.farmer,
            "Role=>Farmer can use this function"
        );

        return getNoOfPackagesOfFarmer();
    }

    function farmerGetRawMaterialAddresses()
        external
        view
        returns (address[] memory)
    {
        address[] memory ret = getAllPackages();
        return ret;
    }

    ///////////////  Transporter ///////////////

    function transporterHandlePackage(
        address _address,
        uint256 transporterType,
        address cid
    ) external {
        require(
            userInfo[msg.sender].role == roles.transporter,
            "Only Transporter can call this function"
        );
        require(transporterType > 0, "Transporter Type is incorrect");

        handlePackage(_address, transporterType, cid);
    }

    ///////////////  Processor ///////////////

    function processorReceivedCrops(address _addr) external {
        require(
            userInfo[msg.sender].role == roles.processor,
            "Only Processor can access this function"
        );
        processorReceivedPackage(_addr, msg.sender);
    }

    function processorCreatesNewProduct(
        bytes32 _description,
        address[] memory _cropAddr,
        uint256 _quantity,
        address[] memory _transporterAddr,
        address _receiverAddr,
        uint256 RcvrType
    ) external returns (string memory) {
        require(
            userInfo[msg.sender].role == roles.processor,
            "Only Processor can create Product"
        );
        require(RcvrType != 0, "Reciever Type should be defined");

        processorCreatesProduct(
            msg.sender,
            _description,
            _cropAddr,
            _quantity,
            _transporterAddr,
            _receiverAddr,
            RcvrType
        );

        return "Product created!";
    }

    ///////////////  Wholesaler  ///////////////

    function wholesalerReceivedProduct(address _address) external {
        require(
            userInfo[msg.sender].role == roles.wholesaler ||
                userInfo[msg.sender].role == roles.distributor,
            "Only Wholesaler and Distributor can call this function"
        );

        productRecievedAtWholesaler(_address);
    }

    function transferProductW_D(
        address _address,
        address transporter,
        address receiver
    ) external {
        require(
            userInfo[msg.sender].role == roles.wholesaler &&
                msg.sender == Product(_address).getWDC()[0],
            "Only Wholesaler or current owner of package can call this function"
        );

        transferProductWtoD(_address, transporter, receiver);
    }

    function getBatchIdByIndexWD(uint256 index)
        external
        view
        returns (address packageID)
    {
        require(
            userInfo[msg.sender].role == roles.wholesaler,
            "Only Wholesaler Can call this function."
        );
        return ProductWtoD[msg.sender][index];
    }

    function getSubContractWD(address _address)
        external
        view
        returns (address SubContractWD)
    {
        return ProductWtoDTxContract[_address];
    }

    ///////////////  Distributor  ///////////////

    function distributorReceivedProduct(address _address, address cid)
        external
    {
        require(
            userInfo[msg.sender].role == roles.distributor &&
                msg.sender == Product(_address).getWDC()[1],
            "Only Distributor or current owner of package can call this function"
        );

        productRecievedAtDistributor(_address, cid);
    }

    function distributorTransferProducttoCustomer(
        address _address,
        address transporter,
        address receiver
    ) external {
        require(
            userInfo[msg.sender].role == roles.distributor &&
                msg.sender == Product(_address).getWDC()[1],
            "Only Distributor or current owner of package can call this function"
        );
        transferProductDtoC(_address, transporter, receiver);
    }

    function getBatchesCountDC() external view returns (uint256 count) {
        require(
            userInfo[msg.sender].role == roles.distributor,
            "Only Distributor Can call this function."
        );
        return ProductDtoC[msg.sender].length;
    }

    function getBatchIdByIndexDC(uint256 index)
        external
        view
        returns (address packageID)
    {
        require(
            userInfo[msg.sender].role == roles.distributor,
            "Only Distributor Can call this function."
        );
        return ProductDtoC[msg.sender][index];
    }

    function getSubContractDC(address _address)
        external
        view
        returns (address SubContractDP)
    {
        return ProductDtoCTxContract[_address];
    }

    ///////////////  Customer  ///////////////

    function customerReceivedProduct(address _address, address cid) external {
        require(
            userInfo[msg.sender].role == roles.customer,
            "Only Customer Can call this function."
        );
        productRecievedAtCustomer(_address, cid);
    }

    function updateStatus(address _address, uint256 Status) external {
        require(
            userInfo[msg.sender].role == roles.customer &&
                msg.sender == Product(_address).getWDC()[2],
            "Only Customer or current owner of package can call this function"
        );
        require(sale[_address] == salestatus(1), "Product Must be at Customer");

        updateSaleStatus(_address, Status);
    }

    function getSalesInfo(address _address)
        external
        view
        returns (uint256 Status)
    {
        return salesInfo(_address);
    }

    function getBatchesCountC() external view returns (uint256 count) {
        require(
            userInfo[msg.sender].role == roles.customer,
            "Only Wholesaler or current owner of package can call this function"
        );
        return ProductBatchAtCustomer[msg.sender].length;
    }

    function getBatchIdByIndexC(uint256 index)
        external
        view
        returns (address _address)
    {
        require(
            userInfo[msg.sender].role == roles.customer,
            "Only Wholesaler or current owner of package can call this function"
        );
        return ProductBatchAtCustomer[msg.sender][index];
    }

    // function verify(address p, bytes32 hash, uint8 v, bytes32 r, bytes32 s) external view returns(bool) {
    //     return ecrecover(hash, v, r, s) == p;
    // }
}
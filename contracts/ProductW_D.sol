// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import './Product.sol';

contract ProductW_D {

    address Owner;

    enum packageStatus { atcreator, picked, delivered }

    address productId;
    address sender;
    address transporter;
    address receiver;
    packageStatus status;

    constructor(
        address _address,
        address Sender,
        address Transporter,
        address Receiver
    ) public {
        Owner = Sender;
        productId = _address;
        sender = Sender;
        transporter = Transporter;
        receiver = Receiver;
        status = packageStatus(0);
    }

    function updateTransporterAddress(address addr) public {
        transporter = addr;
    }



    function pickWD(
        address _address,
        address _transporter
    ) public {
        require(
            transporter == _transporter,
            "Only Associated shipper can call this function."
        );
        status = packageStatus(1);

        Product(_address).sendWtoD(
            receiver,
            sender
        );
    }

    function receiveWD(
        address _address,
        address Receiver
    ) public {
        require(
            Receiver == receiver,
            "Only Associated receiver can call this function."
        );
        status = packageStatus(2);

        Product(_address).receivedWtoD(
            Receiver
        );
    }

    function getBatchIDStatus() public view returns(
        uint
    ) {
        return uint(status);
    }

}
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

/* ========== FORGE DEPENDENDCIES ========== */
import "../../lib/ds-test/src/test.sol";
import "./utils/Vm.sol";
import "./utils/console.sol";

/* ========== INTERFACES ========== */
import "./interfaces/IERC20.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IBond.sol";
import "./interfaces/ITreasury.sol";

/* ========== CONTRACT DEPENDENCIES ========== */
import "@openzeppelin/contracts/math/SafeMath.sol";
import {RomeProFactory, CustomBond, CustomTreasury} from "../contracts/factory.sol";
import {RomeProFactoryStorage} from "../contracts/factoryStorage.sol";
import {RPSubsidyRouter} from "../contracts/subsidy.sol";
import {GenericBondingCalculator} from "../contracts/genericBondingCalculator.sol";

contract BondSimulation {
    using SafeMath for uint;

    // Instantiate CheatCode interface. Call Cheatcodes to this contract.
    Vm internal constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    // Fork Principle Token. Change this for each new partner.
    IUniswapV2Pair principle = IUniswapV2Pair(0xdF1d4C921Fe6a04eF086b4191E8742eCfbDAa355);

    // Fork Payout Token. Change this for each new partner.
    IERC20 payout = IERC20(0x10010078a54396F62c96dF8532dc2B4847d47ED3);

    // Fork Movr Token
    IERC20 wmovr = IERC20(0x98878B06940aE243284CA214f92Bb71a2b032B8A);

    // Fork Solarbeam Router
    IRouter router = IRouter(0xAA30eF758139ae4a7f798112902Bf6d65612045f);

    // State Storage
    RomeProFactoryStorage factoryStorage;
    RPSubsidyRouter subsidy;
    GenericBondingCalculator calculator;
    RomeProFactory factory;
    CustomTreasury treasury;
    CustomBond bond;
    address initialOwner;
    uint capacity;
    uint duration;
    uint vestingTerm;
    uint bcv;
    uint minPrice;
    uint maxPayout;
    uint initialDebt;
    uint maxDebt;
    
    // Fees. Default 3.3% flat
    uint[] _tiers = [0];
    uint[] _fees = [33300];

    function setUp() public {

        // Deploy FactoryStorage, Router, Calculator
        factoryStorage = new RomeProFactoryStorage();
        subsidy = new RPSubsidyRouter();
        calculator = new GenericBondingCalculator();

        // Deploy Factory
        factory = new RomeProFactory(
            address(0x3a3eE61F7c6e1994a2001762250A5E17B2061b6d), // Dummy Address for Treasury
            address(factoryStorage),
            address(subsidy),
            address(this) // Rome Dao Access control
        );

        // Toggle factory address in storage
        factoryStorage.setFactoryAddress(address(factory));

        // Partner Multisig.
        initialOwner = 0xBf3bD01bd5fB28d2381d41A8eF779E6aa6f0a811;
        
        // Deploy Custom Bond and Treasury
        ( 
            address _treasury, 
            address _bond 
        ) = factory.createBondAndTreasury(
            address(payout),
            address(principle),
            initialOwner,
            _tiers,
            _fees
        );
        treasury = CustomTreasury(_treasury);
        bond = CustomBond(_bond);
    }
    function test_simulation() public {
    
        console.log("|==================== USER INPUTS ====================|");
        capacity = 58700 * 1e18;
        duration = 145152; // 3 week worth of blocks.
        vestingTerm = 34560; // Vesting term in blocks.
        bcv = controlVariable( capacity, vestingTerm, duration ).mul(100000 + 10000).div(100000); // 1000 = 1% adjustment to bcv
        minPrice = price(1000); // 1000 is 10% discount
        maxPayout = 1; // Percent of total supply, 1000 = 1% Percent
        initialDebt = uint(1095392314285714285714).mul(5000).div(10000);
        maxDebt = 1500*1e18;

        // Print User Inputs
        console.log( "Market Price Payout per Principle (7) ", calculator.valuation( address(principle), address(payout) ).div(1e11) );
        console.log( "Market Price Principle Per Payout (7) =:", price(0));
        console.log( "capacity (18) =:", capacity.div( 10 ** payout.decimals() ) );
        console.log( "control variable =:", bcv );
        console.log( "min price (7) =:", minPrice);
        console.log( "initial Debt =:", initialDebt);
        console.log("|=====================================================|");

        // Set Vesting Rate
        vm.startPrank( initialOwner ); // prnaks msg.sender to initialOwner
        bond.setBondTerms( CustomBond.PARAMETER(0), vestingTerm );
        
        // Initalize bond terms
        bond.initializeBond(
            bcv,
            vestingTerm,
            minPrice,
            maxPayout,
            maxDebt,
            initialDebt
        );
    
        // Whitelist Bond
        treasury.toggleBondContract( address(bond) );
        vm.stopPrank();

        // Mint Treasury Capacity
        setBalance( address(treasury), 10 * capacity, address(payout), 2 );

        // Mint depositor movr
        setBalance(address(1),100000*1e18,address(wmovr),3);

        uint bondNumber = 1;
        uint payout_;
        uint totalBonded;
        uint totalPayed;
        uint totalPayoutBonded;
        uint bondSize;
        uint amount = 400*1e18; // Each LP is 2x this deposit
        uint interval = 288; // 1 hour
        console.log("Bond Deposit Size (0) =:",2 * amount.div(1e18));

        vm.startPrank(address(1));
        payout.approve(address(router),type(uint).max/2);
        wmovr.approve(address(router),type(uint).max/2);
        principle.approve(address(bond),type(uint).max/2);

        console.log("bond price B4", bond.bondPrice());
        console.log("true bond price B4", bond.trueBondPrice());
    
        uint end = block.number + duration;

        while (block.number <= end) {
            // mint payout to deposit
            setBalance(address(1),amount,address(payout),2);

            while (bond.trueBondPrice() > price(200)) { // 2% discount ceiling
                vm.roll(block.number + 72); // wait 15 min
            }

            // mint liquidity
            router.addLiquidity(
                address(wmovr),
                address(payout),
                100000*1e18,
                amount,
                0,
                0,
                address(1),
                block.timestamp+900
            );

            console.log("|-----------------------------------------------------|");
            // deposit for bond
            bondSize = principle.balanceOf(address(1));
            payout_ = bond.deposit(bondSize, 200000*1e11, address(1));
            console.log("Bond Number", bondNumber, "payed out (0)", payout_.div(1e18));
            console.log("payed out cumulative", totalPayed.div(1e18));

            // Accounting
            bondNumber++;
            totalBonded += bondSize;
            totalPayed += payout_;
            totalPayoutBonded += (2 * amount);

            if(totalPayed > capacity) {
                console.log("blocks left", end - block.number);
                break;
            }

            // Wait Interval
            vm.roll(block.number + interval);
        }
        console.log("Number of bonds", bondNumber);
        console.log("Total Payout Bonded", totalPayoutBonded.div(1e18));
        console.log("Total Principle Bonded", totalBonded.div(1e18));
        console.log("Total Payed Out", totalPayed.div(1e18));




    }

        /* ========== HELPER FUNCTIONS ========== */

     function setBalance(address _account, uint256 _amount, address _token, uint256 _slot) public {
        vm.store(
            _token,
            keccak256(abi.encode(_account, _slot)),
            bytes32(_amount)
        );
    }

    /**
     * @notice                  returns price in payout tokens at specified discount
     * @param _discount         1000 = 10.00%
     */
    function price( uint _discount ) internal view returns ( uint price_ ) {
        ( uint reserve0, uint reserve1, ) = principle.getReserves();

        uint reserve;

        if ( principle.token0() == address(payout) ) {
            reserve = reserve0;
        } else {
            reserve = reserve1;
        }

        _discount = uint(10000).sub(_discount);

        price_ = _discount.mul(principle.totalSupply().mul(1e7).div(2 * reserve)).div(10000);// why is this 6 decimals not 7?
    }

    /**
     * @notice                  returns payout for _amount principle deposited
     * @param  _amount          amount of principle tokens (18 decimals)
     * @return payout_          amount of payout tokens (payout decimals)
     */
    function payoutFor( uint _amount ) internal view returns ( uint payout_ ) {
        uint a = uint(payout.decimals());
        payout_ = (_amount * (10 ** (a.add(7)) ) ) / price(0) / 1e18;
    }

    /**
     * @notice                  calculates control variable
     * @param  _capacity        payout tokens to distribute over duration.
     * @param  _vestingTerm     length of each bond vesting in blocks
     * @param  _duration        blocks until end of distribution
     */
    function controlVariable( uint _capacity, uint _vestingTerm, uint _duration ) internal view returns ( uint controlVariable_ ) {
        // convert target debt from payout to principle. For now assuming both are 18 decimals. Change this to read decimals in future.
        uint targetDebt = _capacity.mul(_vestingTerm).mul(price(0)).div(_duration).div(1e7);
        console.log("target debt in principle (18)", targetDebt);
        controlVariable_ = price(0).mul(payout.totalSupply()).div(targetDebt).div(1e5); //why div 1e5?
    }
}

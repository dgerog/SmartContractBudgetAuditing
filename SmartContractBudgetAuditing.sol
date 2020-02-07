/*
    SmartContractBudgetAuditing
    ---------------------------
    This is a demo Smart Contract that controls the release of funds according to a specific
    expenses breakdown (i.e. a budget). The idea is to register expenses keywords and then,
    ask the Smart Contract to approve or not a transaction that is recognized by that keyword.
    ------------------------------------------------------------------------------------------
*/
pragma solidity >=0.5.3;

contract SmartContractBudgetAuditing {
    // Budget State
    // >> A budget has three (3) states
    //    1. onAllocation -> Budget allocation entries can be attached - Funds can be updated [DEFAULT - ON CREATION]
    //    2. onExecution -> Budget allocation is completed - Execute => Start consuming funds
    //    3. isCompleted -> Budget execution is completed - No more funds can be consumed
    enum budgetState {onAlocation, onFunding, onExecution, isCompleted}

    // Budget Allocation Struct
    // >> Smart Contract struct to store the break down of a budget.
    struct budgetAllocation {
        string expenseCategory;
        uint256 availableFunds;
        uint256 consumedFunds;
        bool isRepeated;
        bool isActivated;
    }

    // Define Contract Properties
    address public issuer;
    address public beneficiary;
    budgetAllocation[] public budget;
    budgetState public state;
    uint256 public totalFunds;
    uint256 public totalConsumedFunds;

    // Contract restrictions
    modifier onlyIssuer {
        require (
            msg.sender == issuer,
            "Only contract issuer is allowed to update the contract."
        );
        _;
    }
    modifier canUpdateContract {
        require (
            state == budgetState.onAlocation && msg.sender == issuer,
            "Budget allocation is completed. Changes are not allowed."
        );
        _;
    }
    modifier isOnFunding {
        require (
            state == budgetState.onFunding,
            "Budget funding is completed. Cannot add funds."
        );
        _;
    }
    modifier canConsumeFunds {
        require (
            state == budgetState.onExecution && beneficiary == msg.sender,
            "Budget not in execution phase or not the beneficiary of this budget."
        );
        _;
    }
    modifier isCompleted {
        require (
            state == budgetState.isCompleted,
            "Budget execution is completed."
        );
        _;
    }


    //
    // Construct contract
    //
    constructor(address _beneficiary, uint256 _total) public {
        issuer = msg.sender;
        beneficiary = _beneficiary;
        totalFunds = _total;
        state = budgetState.onAlocation;
        totalConsumedFunds = 0;
    }


    //
    // Budget manipulation
    //


    // Append/Edit budget allocation
    function allocateFunds(string memory expenseCategory, uint256 availableFunds, bool isRepeated) public canUpdateContract {
        require (
            availableFunds>0 && availableFunds <= totalFunds,
            "Funds must be greater than zero and less than total budget."
        );
        budgetAllocation memory newAlloc;
            newAlloc.expenseCategory = expenseCategory;
            newAlloc.availableFunds = availableFunds;
            newAlloc.consumedFunds = 0;
            newAlloc.isRepeated = isRepeated;
            newAlloc.isActivated = false;

        //update OR add budget entry
        uint256 i = 0;
        for (i = 0; i<budget.length; i++) {
            if (compareStrings(budget[i].expenseCategory, expenseCategory))
                break;
        }

        if (i < budget.length)
            budget[i] = newAlloc;
        else
            budget.push(newAlloc);
    }

    // Remove budget allocation
    function removeExpenseCategory(string memory expenseCategory) public canUpdateContract {
        bool isFound = false; uint256 i = 0;
        for (i = 0; i<budget.length && !isFound; i++)
            isFound = compareStrings(budget[i].expenseCategory, expenseCategory);

        if (isFound) {
            while (i<budget.length-1)
                budget[i] = budget[++i];
             budget.pop(); //free space
        }
    }


    //
    // Control budget states
    //


    // Activate contract (transfer also the crypto funds)
    function startExecution() public canUpdateContract {
        require (
            budget.length != 0,
            "Budget allocation is empty. Please add funds."
        );
        state = budgetState.onExecution;
    }

    // Terminate contract
    function finalizeBudget() public onlyIssuer {
        state = budgetState.isCompleted;
    }

    //
    // Auditing & Clearence
    //
    function clearTransaction(string memory expenseCategory, uint256 amount, bool commitAnyway) public canConsumeFunds returns (bool) {
        //1. First check: Is this type of expense permited?
        uint256 i = 0;
        for (i = 0; i<budget.length; i++) {
            if (compareStrings(budget[i].expenseCategory, expenseCategory))
                break;
        }
        if (i < budget.length) {
            //2. Second check: Is it alredy activated?
            if (!budget[i].isRepeated && budget[i].isActivated) {
                //this type of expense is allowed, but only once
                return (false);
            }
            else {
                //3. Are there enough funds?
                if (budget[i].availableFunds != 0) {
                    if (amount > budget[i].availableFunds) {
                        //4. This type of expense is allowed, not activated but not enough money (do as instructed - commitAnyway)
                        if (commitAnyway) {
                            //proceed with the residual funds
                            budget[i].isActivated = true;
                            budget[i].availableFunds = 0;
                            budget[i].consumedFunds = budget[i].consumedFunds + budget[i].availableFunds;

                            //update global fund tracking counter
                            totalConsumedFunds = totalConsumedFunds + budget[i].availableFunds;
                            return(true);
                        }
                        else {
                            //fail
                            return (false);
                        }
                    }
                    else {
                        //all set -> checks passed, clear transaction
                        budget[i].isActivated = true;
                        budget[i].availableFunds = budget[i].availableFunds - amount;
                        budget[i].consumedFunds = budget[i].consumedFunds + amount;

                        //update global fund tracking counter
                        totalConsumedFunds = totalConsumedFunds + amount;
                        return (true);
                    }
                }
                else {
                    //fail - all the available funds have been consumed
                    return (false);        
                }
            }
        }
        else {
            //fail - this type of expense is not allowed
            return (false);
        }
    }

    //
    // Some utility functions (private)
    //
    function compareStrings (string memory a, string memory b) private pure returns (bool) {
           return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))) );
    }
}
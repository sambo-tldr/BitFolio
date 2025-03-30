# BitFolio Smart Contract Documentation

**Version 1.0.0**  
_Decentralized Portfolio Management on Stacks L2_

---

### **Overview**

BitFolio is a non-custodial portfolio management protocol enabling users to create, manage, and automatically rebalance tokenized asset portfolios on the Stacks blockchain. Designed for Bitcoin compliance, it leverages Clarity’s security and Stacks L2 scalability to provide institutional-grade asset allocation tools.

---

### **Key Features**

1. **Portfolio Creation**

   - Create portfolios with up to 10 digital assets
   - Define target allocation percentages (0.01% precision)
   - Immutable creation records with blockchain timestamps

2. **Automated Rebalancing**

   - 24-hour rebalancing cycles enforced at the smart contract level
   - Protocol-managed value tracking (`total-value` field)

3. **Fee Structure**

   - 0.25% management fee (25 basis points)
   - Fee logic ready for future implementation

4. **Security Controls**

   - Principal-based ownership verification
   - Reentrancy-safe function design
   - Explicit error codes for all failure modes

5. **Cross-Token Compliance**
   - Token validity checks during portfolio creation
   - ERC-20/SPT compatibility through address validation

---

### **Technical Architecture**

#### **Data Structures**

- **Portfolios Map**

  ```clarity
  (define-map Portfolios
    uint
    {
      owner: principal,
      created-at: uint,
      last-rebalanced: uint,
      total-value: uint,
      active: bool,
      token-count: uint
    }
  )
  ```

- **PortfolioAssets Map**
  ```clarity
  (define-map PortfolioAssets
    {portfolio-id: uint, token-id: uint}
    {
      target-percentage: uint,
      current-amount: uint,
      token-address: principal
    }
  )
  ```

#### **Core Functions**

- **`create-portfolio`**

  - Initializes new portfolios with token allocations
  - Validates:
    - Token count ≤ 10 (`MAX-TOKENS-PER-PORTFOLIO`)
    - Percentage sum = 10,000 basis points

- **`rebalance-portfolio`**

  - Enforces 24-hour cooldown via block height checks
  - Updates `last-rebalanced` timestamp

- **`update-portfolio-allocation`**
  - Allows owners to modify asset percentages
  - Includes boundary checks (0 ≤ % ≤ 100)

---

### **Error Handling**

| Error Code              | ID   | Description                      |
| ----------------------- | ---- | -------------------------------- |
| ERR-NOT-AUTHORIZED      | u100 | Unauthorized principal action    |
| ERR-INVALID-PORTFOLIO   | u101 | Nonexistent portfolio ID         |
| ERR-INVALID-PERCENTAGE  | u106 | Allocation outside 0-100% range  |
| ERR-MAX-TOKENS-EXCEEDED | u107 | Portfolio exceeds 10-token limit |

_Full error code list available in contract source._

---

### **Security Model**

1. **Non-Custodial Design**

   - Users retain full asset ownership
   - No direct token transfers in contract logic

2. **Clarity Language Advantages**

   - Predictable execution costs
   - Static analysis compatibility

3. **Access Controls**

   - Owner-restricted critical functions
   - Principal-based permission system

4. **Reentrancy Protection**
   - State changes before external calls

---

### **Deployment**

#### **Requirements**

- Clarinet 2.0+
- Stacks Testnet/Local Devnet

#### **Steps**

1. Initialize project:

   ```bash
   clarinet new bitfolio-project
   ```

2. Add contract to `./contracts` directory

3. Validate syntax:

   ```bash
   clarinet check
   ```

---

### **Testing Strategy**

1. **Unit Tests**

   - Portfolio creation with valid/invalid parameters
   - Rebalancing time lock verification

2. **Integration Tests**

   - Cross-contract token validation
   - Fee calculation simulations

3. **Stress Tests**
   - 10-token portfolio edge cases
   - High-frequency rebalance attempts

---

### **Audit Status**

- **Formal Verification:** Pending
- **Third-Party Audit:** Scheduled Q4 2024

---

### **Contributing**

1. Fork repository
2. Create feature branch (`feature/[component]-[description]`)
3. Submit PR with:
   - Test coverage proof
   - Clarinet check output
   - Impact analysis

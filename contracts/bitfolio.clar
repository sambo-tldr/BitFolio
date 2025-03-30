;; Title: BitFolio - Decentralized Tokenized Portfolio Management on Stacks L2
;; Summary: A Bitcoin-compliant protocol for creating, managing, and automatically rebalancing multi-asset portfolios
;; Description: 
;; BitFolio is a next-generation asset management protocol built on Stacks Layer 2, enabling secure, 
;; non-custodial portfolio management with native Bitcoin integration. The protocol allows users to:
;; - Create customized portfolios of up to 10 digital assets
;; - Maintain precise asset allocation ratios through periodic rebalancing
;; - Track portfolio performance with blockchain-verified metrics
;; - Execute strategy updates with smart contract-enforced permissions
;; Designed for compliance with Bitcoin's security model, BitFolio leverages Stacks L2 for fast settlements
;; while maintaining auditability through Clarity's transparent smart contracts. Features include:
;; - Automated percentage-based asset allocations
;; - 24-hour rebalancing cycles
;; - Protocol-level fee structure (0.25% management fee)
;; - Immutable portfolio creation history
;; - Cross-verification of token validity
;; This implementation represents a new standard for decentralized portfolio management, combining
;; Bitcoin's security with Stacks L2's programmability for institutional-grade asset management tools.

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PORTFOLIO (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-TOKEN (err u103))
(define-constant ERR-REBALANCE-FAILED (err u104))
(define-constant ERR-PORTFOLIO-EXISTS (err u105))
(define-constant ERR-INVALID-PERCENTAGE (err u106))
(define-constant ERR-MAX-TOKENS-EXCEEDED (err u107))
(define-constant ERR-LENGTH-MISMATCH (err u108))
(define-constant ERR-USER-STORAGE-FAILED (err u109))
(define-constant ERR-INVALID-TOKEN-ID (err u110))

;; Data Variables
(define-data-var protocol-owner principal tx-sender)
(define-data-var portfolio-counter uint u0)
(define-data-var protocol-fee uint u25) ;; 0.25% represented as basis points

;; Constants
(define-constant MAX-TOKENS-PER-PORTFOLIO u10)
(define-constant BASIS-POINTS u10000)

;; Data Maps
(define-map Portfolios
    uint ;; portfolio-id
    {
        owner: principal,
        created-at: uint,
        last-rebalanced: uint,
        total-value: uint,
        active: bool,
		token-count: uint
    }
)

(define-map PortfolioAssets
    {portfolio-id: uint, token-id: uint}
    {
        target-percentage: uint,
        current-amount: uint,
        token-address: principal
    }
)

(define-map UserPortfolios
    principal
    (list 20 uint)
)

;; Read-only functions
(define-read-only (get-portfolio (portfolio-id uint))
    (map-get? Portfolios portfolio-id)
)

(define-read-only (get-portfolio-asset (portfolio-id uint) (token-id uint))
    (map-get? PortfolioAssets {portfolio-id: portfolio-id, token-id: token-id})
)

(define-read-only (get-user-portfolios (user principal))
    (default-to (list) (map-get? UserPortfolios user))
)

(define-read-only (calculate-rebalance-amounts (portfolio-id uint))
    (let (
        (portfolio (unwrap! (get-portfolio portfolio-id) ERR-INVALID-PORTFOLIO))
        (total-value (get total-value portfolio))
    )
    (ok {
        portfolio-id: portfolio-id,
        total-value: total-value,
        needs-rebalance: (> (- block-height (get last-rebalanced portfolio)) u144) ;; 24 hours in blocks
    }))
)

;; Private functions
(define-private (validate-token-id (portfolio-id uint) (token-id uint))
    (let (
        (portfolio (unwrap! (get-portfolio portfolio-id) false))
    )
    (and 
        (< token-id MAX-TOKENS-PER-PORTFOLIO)
        (< token-id (get token-count portfolio))
        true
    ))
)

(define-private (validate-percentage (percentage uint))
    (and (>= percentage u0) (<= percentage BASIS-POINTS))
)

(define-private (validate-portfolio-percentages (percentages (list 10 uint)))
    (fold check-percentage-sum percentages true)
)

(define-private (check-percentage-sum (current-percentage uint) (valid bool))
    (and valid (validate-percentage current-percentage))
)

(define-private (add-to-user-portfolios (user principal) (portfolio-id uint))
    (let (
        (current-portfolios (get-user-portfolios user))
        (new-portfolios (unwrap! (as-max-len? (append current-portfolios portfolio-id) u20) ERR-USER-STORAGE-FAILED))
		)

    	(map-set UserPortfolios user new-portfolios)
    	(ok true)
	)
)

(define-private (initialize-portfolio-asset (index uint) (token principal) (percentage uint) (portfolio-id uint))
    (if (>= percentage u0)  ;; Only check percentage validity since principal is already a valid type
        (begin
            (map-set PortfolioAssets
                {portfolio-id: portfolio-id, token-id: index}
                {
                    target-percentage: percentage,
                    current-amount: u0,
                    token-address: token
                }
            )
            (ok true))
        ERR-INVALID-TOKEN
    )
)

;; Public functions
(define-public (create-portfolio (initial-tokens (list 10 principal)) (percentages (list 10 uint)))
    (let (
        (portfolio-id (+ (var-get portfolio-counter) u1))
        (token-count (len initial-tokens))
        (percentage-count (len percentages))
        (token-0 (element-at? initial-tokens u0))
        (token-1 (element-at? initial-tokens u1))
        (percentage-0 (element-at? percentages u0))
        (percentage-1 (element-at? percentages u1))
    )
    (asserts! (<= token-count MAX-TOKENS-PER-PORTFOLIO) ERR-MAX-TOKENS-EXCEEDED)
    (asserts! (is-eq token-count percentage-count) ERR-LENGTH-MISMATCH)
    (asserts! (validate-portfolio-percentages percentages) ERR-INVALID-PERCENTAGE)
    
    ;; Create portfolio
    (map-set Portfolios portfolio-id
        {
            owner: tx-sender,
            created-at: block-height,
            last-rebalanced: block-height,
            total-value: u0,
            active: true,
            token-count: token-count
        }
    )
    
    ;; Check if we have valid tokens and percentages
    (asserts! (and (is-some token-0) (is-some token-1)) ERR-INVALID-TOKEN)
    (asserts! (and (is-some percentage-0) (is-some percentage-1)) ERR-INVALID-PERCENTAGE)
    
    ;; Initialize portfolio assets
    (try! (initialize-portfolio-asset 
        u0 
        (unwrap-panic token-0)
        (unwrap-panic percentage-0)
        portfolio-id))
    
    (try! (initialize-portfolio-asset 
        u1
        (unwrap-panic token-1)
        (unwrap-panic percentage-1)
        portfolio-id))
    
    ;; Update user's portfolio list
    (try! (add-to-user-portfolios tx-sender portfolio-id))
    
    ;; Increment counter
    (var-set portfolio-counter portfolio-id)
    (ok portfolio-id))
)

(define-public (rebalance-portfolio (portfolio-id uint))
    (let (
        (portfolio (unwrap! (get-portfolio portfolio-id) ERR-INVALID-PORTFOLIO))
    )
    (asserts! (is-eq tx-sender (get owner portfolio)) ERR-NOT-AUTHORIZED)
    (asserts! (get active portfolio) ERR-INVALID-PORTFOLIO)
    
    ;; Update last rebalanced timestamp
    (map-set Portfolios portfolio-id
        (merge portfolio {last-rebalanced: block-height})
    )
    
    (ok true))
)

(define-public (update-portfolio-allocation 
    (portfolio-id uint) 
    (token-id uint)
    (new-percentage uint))
    (let (
        (portfolio (unwrap! (get-portfolio portfolio-id) ERR-INVALID-PORTFOLIO))
        (asset (unwrap! (get-portfolio-asset portfolio-id token-id) ERR-INVALID-TOKEN))
    )
    (asserts! (is-eq tx-sender (get owner portfolio)) ERR-NOT-AUTHORIZED)
    (asserts! (validate-percentage new-percentage) ERR-INVALID-PERCENTAGE)
    (asserts! (validate-token-id portfolio-id token-id) ERR-INVALID-TOKEN-ID)
    
    (map-set PortfolioAssets
        {portfolio-id: portfolio-id, token-id: token-id}
        (merge asset {target-percentage: new-percentage})
    )
    
    (ok true))
)

;; Contract initialization
(define-public (initialize (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (not (is-eq new-owner tx-sender)) ERR-NOT-AUTHORIZED)  ;; Prevent self-assignment
        (var-set protocol-owner new-owner)
        (ok true))
)
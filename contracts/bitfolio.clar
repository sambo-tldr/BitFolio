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
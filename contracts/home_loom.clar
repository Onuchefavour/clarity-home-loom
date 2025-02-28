;; HomeLoom Contract
(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-space (err u101))
(define-constant err-not-found (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-rate-limit (err u105))
(define-constant err-unauthorized (err u106))

;; Events
(define-data-var last-event-id uint u0)
(define-map events 
    uint 
    {
        event-type: (string-utf8 32),
        space-id: uint,
        actor: principal,
        timestamp: uint
    }
)

;; Fungible Token
(define-fungible-token hlm)

;; Data Variables
(define-data-var last-space-id uint u0)
(define-data-var token-uri (string-utf8 256) "https://homeloom.xyz/metadata/")
(define-data-var reward-amount uint u100)

;; Rate Limiting
(define-map user-last-tip
    principal
    uint
)

;; Data Maps
(define-map spaces 
    uint 
    {
        owner: principal,
        name: (string-utf8 64),
        description: (string-utf8 256),
        category: (string-utf8 32),
        tips: (list 10 uint),
        progress: uint,
        milestone-claimed: bool,
        created-at: uint
    }
)

(define-map tips
    uint
    {
        author: principal,
        content: (string-utf8 256),
        likes: uint,
        edited: bool,
        created-at: uint
    }
)

;; Helper Functions
(define-private (emit-event (event-type (string-utf8 32)) (space-id uint))
    (let
        (
            (event-id (+ (var-get last-event-id) u1))
        )
        (map-set events event-id {
            event-type: event-type,
            space-id: space-id,
            actor: tx-sender,
            timestamp: block-height
        })
        (var-set last-event-id event-id)
        (ok event-id)
    )
)

(define-private (validate-tip-rate-limit)
    (let
        (
            (last-tip-time (default-to u0 (map-get? user-last-tip tx-sender)))
        )
        (if (> (- block-height last-tip-time) u144)
            (ok true)
            err-rate-limit
        )
    )
)

;; Public Functions
(define-public (create-space (name (string-utf8 64)) (description (string-utf8 256)) (category (string-utf8 32)))
    (let
        (
            (new-id (+ (var-get last-space-id) u1))
        )
        (asserts! (> (len name) u0) err-invalid-input)
        (try! (nft-mint? home-loom new-id tx-sender))
        (map-set spaces new-id {
            owner: tx-sender,
            name: name,
            description: description,
            category: category,
            tips: (list),
            progress: u0,
            milestone-claimed: false,
            created-at: block-height
        })
        (var-set last-space-id new-id)
        (try! (emit-event "space-created" new-id))
        (ok new-id)
    )
)

(define-public (add-tip (space-id uint) (content (string-utf8 256)))
    (let
        (
            (tip-id (+ (var-get last-space-id) u1))
        )
        (asserts! (> (len content) u0) err-invalid-input)
        (try! (validate-tip-rate-limit))
        (map-set tips tip-id {
            author: tx-sender,
            content: content,
            likes: u0,
            edited: false,
            created-at: block-height
        })
        (map-set user-last-tip tx-sender block-height)
        (try! (emit-event "tip-added" space-id))
        (ok tip-id)
    )
)

;; [Rest of the contract functions remain the same with added event emissions]

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
(define-constant err-paused (err u107))

;; Contract Status
(define-data-var contract-paused bool false)
(define-data-var token-max-supply uint u1000000)

;; Event Types
(define-constant event-space-created "space-created")
(define-constant event-tip-added "tip-added")
(define-constant event-milestone-claimed "milestone-claimed")
(define-constant event-token-minted "token-minted")

;; Events
(define-data-var last-event-id uint u0)
(define-map events 
    uint 
    {
        event-type: (string-utf8 32),
        space-id: uint,
        actor: principal,
        timestamp: uint,
        data: (optional (string-utf8 256))
    }
)

;; Rate Limiting
(define-map user-activity
    principal
    {
        last-tip-time: uint,
        tip-count: uint,
        rate-limit: uint
    }
)

;; [Previous maps and data vars remain the same]

;; Administrative Functions
(define-public (set-paused (paused bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set contract-paused paused)
        (ok true)
    )
)

(define-private (check-not-paused)
    (ok (asserts! (not (var-get contract-paused)) err-paused))
)

;; Enhanced Rate Limiting
(define-private (validate-tip-rate-limit)
    (let
        (
            (user-stats (default-to 
                { last-tip-time: u0, tip-count: u0, rate-limit: u144 }
                (map-get? user-activity tx-sender)
            ))
            (current-limit (get rate-limit user-stats))
        )
        (if (> (- block-height (get last-tip-time user-stats)) current-limit)
            (begin
                (map-set user-activity tx-sender
                    {
                        last-tip-time: block-height,
                        tip-count: (+ (get tip-count user-stats) u1),
                        rate-limit: (if (> (get tip-count user-stats) u10)
                            (/ current-limit u2)
                            current-limit)
                    }
                )
                (ok true)
            )
            err-rate-limit
        )
    )
)

;; Enhanced Event System
(define-public (get-events-by-type (event-type (string-utf8 32)) (limit uint))
    (let
        ((current-id (var-get last-event-id)))
        (ok (filter get-event-by-type 
            (range (- current-id limit) current-id)))
    )
)

(define-private (get-event-by-type (id uint))
    (match (map-get? events id)
        event (is-eq (get event-type event) event-type)
        false
    )
)

;; [Rest of the contract functions updated with check-not-paused]

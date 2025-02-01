;; HomeLoom Contract
(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-space (err u101))
(define-constant err-not-found (err u102))
(define-constant err-insufficient-funds (err u103))

;; Fungible Token
(define-fungible-token hlm)

;; Data Variables
(define-data-var last-space-id uint u0)
(define-data-var token-uri (string-utf8 256) "https://homeloom.xyz/metadata/")
(define-data-var reward-amount uint u100)

;; Data Maps
(define-map spaces 
    uint 
    {
        owner: principal,
        name: (string-utf8 64),
        description: (string-utf8 256),
        tips: (list 10 uint),
        progress: uint,
        milestone-claimed: bool
    }
)

(define-map tips
    uint
    {
        author: principal,
        content: (string-utf8 256),
        likes: uint
    }
)

;; Public Functions
(define-public (create-space (name (string-utf8 64)) (description (string-utf8 256)))
    (let
        (
            (new-id (+ (var-get last-space-id) u1))
        )
        (try! (nft-mint? home-loom new-id tx-sender))
        (map-set spaces new-id {
            owner: tx-sender,
            name: name,
            description: description,
            tips: (list),
            progress: u0,
            milestone-claimed: false
        })
        (var-set last-space-id new-id)
        (ok new-id)
    )
)

(define-public (add-tip (space-id uint) (content (string-utf8 256)))
    (let
        (
            (tip-id (+ (var-get last-space-id) u1))
        )
        (map-set tips tip-id {
            author: tx-sender,
            content: content,
            likes: u0
        })
        (ok tip-id)
    )
)

(define-public (update-progress (space-id uint) (new-progress uint))
    (let
        (
            (space (unwrap! (map-get? spaces space-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get owner space)) err-owner-only)
        (map-set spaces space-id (merge space {progress: new-progress}))
        (if (and (>= new-progress u100) (not (get milestone-claimed space)))
            (claim-milestone space-id)
            (ok true))
    )
)

(define-public (claim-milestone (space-id uint))
    (let
        (
            (space (unwrap! (map-get? spaces space-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get owner space)) err-owner-only)
        (asserts! (>= (get progress space) u100) err-invalid-space)
        (asserts! (not (get milestone-claimed space)) err-invalid-space)
        (try! (ft-mint? hlm (var-get reward-amount) tx-sender))
        (map-set spaces space-id (merge space {milestone-claimed: true}))
        (ok true)
    )
)

(define-public (like-tip (tip-id uint))
    (let
        (
            (tip (unwrap! (map-get? tips tip-id) err-not-found))
            (author (get author tip))
        )
        (try! (ft-mint? hlm u10 author))
        (map-set tips tip-id (merge tip {likes: (+ (get likes tip) u1)}))
        (ok true)
    )
)

;; Read-only Functions
(define-read-only (get-space (space-id uint))
    (ok (map-get? spaces space-id))
)

(define-read-only (get-tip (tip-id uint))
    (ok (map-get? tips tip-id))
)

(define-read-only (get-balance (account principal))
    (ok (ft-get-balance hlm account))
)

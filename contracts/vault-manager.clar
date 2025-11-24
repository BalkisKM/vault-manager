;; -------------------------------------------------------------
;; Contract: vault-manager.clar
;; Description: Manages user vaults for storing and withdrawing STX
;; -------------------------------------------------------------

(define-constant ERR-NOT-OWNER u100)
(define-constant ERR-NO-VAULT u101)
(define-constant ERR-VAULT-EXISTS u102)
(define-constant ERR-ZERO-AMOUNT u103)
(define-constant ERR-INSUFFICIENT-FUNDS u104)

;; -----------------------------
;; Data Variables
;; -----------------------------

(define-data-var owner (optional principal) none)
(define-data-var total-vaults uint u0)
(define-data-var total-balance uint u0)

;; user -> vault {balance, active}
(define-map vaults
  { user: principal }
  { balance: uint, active: bool })

;; -----------------------------
;; Initialization
;; -----------------------------

(define-public (initialize)
  (if (is-some (var-get owner))
      (err ERR-NOT-OWNER)
      (begin
        (var-set owner (some tx-sender))
        (ok true)
      )
  )
)

;; -----------------------------
;; Create Vault
;; -----------------------------

(define-public (create-vault)
  (let ((sender tx-sender))
    (match (map-get? vaults { user: sender })
      some-v
        (if (get active some-v)
            (err ERR-VAULT-EXISTS)
            (begin
              (map-set vaults { user: sender } { balance: u0, active: true })
              (var-set total-vaults (+ (var-get total-vaults) u1))
              (ok true)
            )
        )
      (begin
        (map-set vaults { user: sender } { balance: u0, active: true })
        (var-set total-vaults (+ (var-get total-vaults) u1))
        (ok true)
      )
    )
  )
)

;; -----------------------------
;; Deposit STX
;; -----------------------------

(define-public (deposit (amount uint))
  (let ((sender tx-sender))
    (if (<= amount u0)
        (err ERR-ZERO-AMOUNT)
        (match (map-get? vaults { user: sender })
          some-v
            (if (not (get active some-v))
                (err ERR-NO-VAULT)
                (begin
                  (map-set vaults { user: sender }
                           { balance: (+ (get balance some-v) amount), active: true })
                  (var-set total-balance (+ (var-get total-balance) amount))
                  (ok (+ (get balance some-v) amount))
                )
            )
          (err ERR-NO-VAULT)
        )
    )
  )
)

;; -----------------------------
;; Withdraw STX
;; -----------------------------

(define-public (withdraw (amount uint))
  (let ((sender tx-sender))
    (match (map-get? vaults { user: sender })
      some-v
        (let ((bal (get balance some-v)))
          (if (or (<= amount u0) (> amount bal))
              (err ERR-INSUFFICIENT-FUNDS)
              (begin
                (try! (stx-transfer? amount (as-contract tx-sender) sender))
                (map-set vaults { user: sender }
                         { balance: (- bal amount), active: true })
                (var-set total-balance (- (var-get total-balance) amount))
                (ok (- bal amount))
              )
          )
        )
      (err ERR-NO-VAULT)
    )
  )
)

;; -----------------------------
;; Close Vault
;; -----------------------------

(define-public (close-vault)
  (let ((sender tx-sender))
    (match (map-get? vaults { user: sender })
      some-v
        (let ((bal (get balance some-v)))
          (begin
            (try! (if (> bal u0)
                (stx-transfer? bal (as-contract tx-sender) sender)
                (ok true)
            ))
            (map-delete vaults { user: sender })
            (var-set total-vaults (- (var-get total-vaults) u1))
            (var-set total-balance (- (var-get total-balance) bal))
            (ok true)
          )
        )
      (err ERR-NO-VAULT)
    )
  )
)

;; -----------------------------
;; Owner Controls
;; -----------------------------

(define-public (withdraw-fees (amount uint))
  (let ((o (unwrap! (var-get owner) (err ERR-NOT-OWNER))))
    (if (is-eq tx-sender o)
        (stx-transfer? amount (as-contract tx-sender) o)
        (err ERR-NOT-OWNER)
    )
  )
)

;; -----------------------------
;; Read-only Functions
;; -----------------------------

(define-read-only (get-vault (user principal))
  (match (map-get? vaults { user: user })
    some-v (ok some-v)
    (ok { balance: u0, active: false })
  )
)

(define-read-only (get-total-vaults)
  (ok (var-get total-vaults)))

(define-read-only (get-total-balance)
  (ok (var-get total-balance)))

(define-read-only (get-owner)
  (ok (var-get owner)))

#lang typed/video
(require turnstile/examples/tests/rackunit-typechecking)

;; tests from paper examples

;; TODO:
;; 2017-02-07: swipe transition not working

(define circ-png "circ.png")
(define vid-mp4 "vid.mp4") ; length = 139
(check-type circ-png : String)
(check-type vid-mp4 : String)

;; sec4.1 producers -----------------------------------------------------------

(define g (color "green"))
(define g1 (color "green" #:length 1))
(check-type g : Producer)
(check-type g : (Producer 1))
(check-type g1 : (Producer 1))
(check-not-type g1 : (Producer 2))
(check-not-type g1 : Producer)
(check-type g1 : (Producer 0))

(check-type (color "blue" #:length 3) : (Producer 3))

(define blue-clip (color "blue" #:length 8))
(check-type blue-clip : (Producer 8))

(check-type (image circ-png #:length 3) : (Producer 3))
(check-type (image circ-png #:length (+ 1 2)) : (Producer 3))
(check-type (image circ-png #:length (/ (producer-length blue-clip) 8))
            : (Producer 1))

(check-type (composite-transition 0 0 3/4 3/4) : Transition)
;; ;(check-transition? (swipe-transition #:direction 'up #:length 2)) ; TODO
(check-type (fade-transition #:length 2) : Transition)

;; old fig1
(check-not-type
 (multitrack
  (image circ-png #:length (/ (producer-length blue-clip) 8))
  (composite-transition 0 0 3/4 3/4)
  blue-clip
  #:length 5)
 : Producer)

(check-type
 (multitrack
  (image circ-png #:length (/ (producer-length blue-clip) 8))
  (composite-transition 0 0 3/4 3/4)
  blue-clip
  #:length 5)
 : (Producer 5))

(check-type
 (multitrack
  (image circ-png #:length (/ (producer-length blue-clip) 8))
  (composite-transition 0 0 3/4 3/4)
  blue-clip
  #:length 5)
 : (Producer 4)) ; ok to have longer clip than type specifies

(check-not-type (clip "vid.mp4") : Producer)
(check-type (clip "vid.mp4") : (Producer 139))
(check-type (clip vid-mp4 #:length 3) : (Producer 3))

(check-type (color "blue" #:length 2) : (Producer 2))
(check-type (clip vid-mp4 #:start 100 #:end 103) : (Producer 3))
(check-type (clip vid-mp4 #:start 100 #:end 103) : (Producer 2))
(check-not-type (clip vid-mp4 #:start 100 #:end 103) : Producer)
(check-type (image circ-png #:length 1) : (Producer 1))
(check-type (blank 2) : (Producer 2))
(check-type (blank 2) : (Producer 1)) ; smaller type ok
(check-not-type (blank 2) : (Producer 3)) ; greater not ok

;; sec 4.2 playlists ----------------------------------------------------------
(define circ-img (image circ-png))
(define vid-clip (clip "vid.mp4")) ; length = 139
(check-type circ-img : Producer)
(check-not-type vid-clip : Producer)
(check-type vid-clip : (Producer 139))
(check-type vid-clip : (Producer 138))
(check-not-type vid-clip : (Producer 140))
(check-type (playlist circ-img vid-clip) : Producer)
(check-type (playlist (blank 2) circ-img vid-clip) : Producer)

(define circ3 (image circ-png #:length 3))
(check-type circ3 : (Producer 3))
(check-type (playlist circ3 vid-clip) : (Producer 142))
(check-type (playlist circ3 vid-clip) : (Producer 141))
(check-not-type (playlist circ3 vid-clip) : (Producer 143))
(check-type (playlist (blank 3) circ3 vid-clip) : (Producer 145))

;; TODO: shapes and colors defined after use
(define shapes (playlist circ-img vid-clip))
(define colors (playlist (color "red") (color "blue")))
(check-type shapes : Producer)
(check-type colors : Producer)
(check-type (playlist shapes colors) : Producer)
(check-type (playlist g1) : (Producer 1))
(check-type (playlist blue-clip) : (Producer 8))
(check-not-type (playlist blue-clip) : (Producer 9))
(check-type (playlist g1 blue-clip) : (Producer 9))
(check-not-type (playlist g1 blue-clip) : (Producer 10))
(check-type (playlist (playlist g1) (playlist blue-clip)) : (Producer 9))
(check-not-type (playlist (playlist g1) (playlist blue-clip)) : (Producer 10))
(check-type
 (playlist (image circ-png #:length 3)
           ;(swipe-transition #:direction 'bottom #:duration 2)
           (fade-transition #:length 2)
           (clip vid-mp4 #:length 3))
: (Producer 4))
(check-not-type
 (playlist (image circ-png #:length 3)
           ;(swipe-transition #:direction 'bottom #:duration 2)
           (fade-transition #:length 2)
           (clip vid-mp4 #:length 3))
: (Producer 5))

(check-type
 (playlist (image circ-png #:length 3)
           (clip vid-mp4 #:length 3))
 : (Producer 6))

(check-type
 (playlist
  (image circ-png #:length 2)
  (fade-transition #:length 1)
  (color "blue" #:length 2)
  (fade-transition #:length 2)
  (clip vid-mp4 #:start 0 #:end 3))
 : (Producer 4))
(check-not-type
 (playlist
  (image circ-png #:length 2)
  (fade-transition #:length 1)
  (color "blue" #:length 2)
  (fade-transition #:length 2)
  (clip vid-mp4 #:start 0 #:end 3))
 : (Producer 5))

;; multitracks
(check-type
 (multitrack
  (clip vid-mp4)
  (composite-transition 0 0 3/4 3/4)
  (image circ-png))
 : Producer)

(check-type
 (multitrack
  (clip vid-mp4)
  (composite-transition 0 0 1/2 1/2)
  (multitrack
   (image circ-png)
   (composite-transition 0 1/2 1/2 1/2)
   (color "green")))
 : Producer)

;; defines should be after use?
(define bg (clip vid-mp4))
(define circ (image circ-png))
(define green-color (color "green"))
(define blue-color (color "blue"))
(check-type
 (composite-transition 0 0 1/2 1/2 #:top circ #:bottom bg)
 : Transition)
(check-type
 (composite-transition 1/2 0 1/2 1/2 #:top blue-color #:bottom bg)
 : Transition)
(check-type
 (composite-transition 0 1/2 1/2 1/2 #:top green-color #:bottom bg)
 : Transition)
(check-type (list 1) : (Listof Int))
(check-type
 (list (composite-transition 0 0 1/2 1/2 #:top circ #:bottom bg)
       (composite-transition 1/2 0 1/2 1/2 #:top blue-color #:bottom bg)
       (composite-transition 0 1/2 1/2 1/2 #:top green-color #:bottom bg))
 : (Listof Transition))
(check-type
 (multitrack
  circ bg blue-color green-color
  #:transitions
  (list (composite-transition 0 0 1/2 1/2 #:top circ #:bottom bg)
        (composite-transition 1/2 0 1/2 1/2 #:top blue-color #:bottom bg)
        (composite-transition 0 1/2 1/2 1/2 #:top green-color #:bottom bg)))
 : Producer)

(define swiping-playlist
  (λ ([a : Producer] [b : Producer])
    (playlist a b
              #:transitions
               (composite-transition 0 0 1/2 1/2
                                     #:top a
                                     #:bottom b))))
(check-type (swiping-playlist (image circ-png) (color "green")) : Producer)
(check-type (swiping-playlist (color "green") (clip vid-mp4)) : Producer)


;; filters
(check-type (scale-filter (image circ-png) 1 3) : Producer)

;; props
(define rect-clip (set-property (clip vid-mp4) "bottom?" #t))
;; TODO: how to do this?
(check-type (get-property rect-clip "bottom?" 'bool) : Bool -> #t)
(check-type
 (multitrack
  rect-clip
  (composite-transition
   0
   (if (get-property rect-clip "bottom?" 'bool) 1/2 0)
   1/2 1/2)
  (image circ-png))
 : Producer)

;(include-video "green.vid") ; TODO

;; racketcon
(define logo (image circ-png))
(define sp (blank 100))
(define sl (blank 100))

;; TODO: improve function signatures?
(define (add-slides {n} [sp : (Producer n)]
                        [sl : (Producer n)] → (Producer n))
  (let ([bg (blank (producer-length sp))])
    (multitrack sp sl logo bg
     #:transitions
     (list (composite-transition 0 0 3/10 1 #:top sp #:bottom bg)
           (composite-transition 0 1/2 3/10 1 #:top logo #:bottom bg)
           (composite-transition 1/3 0 2/3 1 #:top sl #:bottom bg))
     #:length (producer-length sp))))

(check-type add-slides
            : (→ #:bind {n} (Producer n) (Producer n) (Producer n)))
;; TODO: should this work? (defines at end)
#;(define (add-bookend main-talk)
  ;; defines are after playlist
  (playlist begin-clip
            (fade-transition 200)
            main-talk
            (fade-transition 200)
            end-clip)
  (define begin-clip (image circ-png #:length 500))
  (define end-clip (image circ-png #:length 500)))

;; TODO: dont need explicit side-condition?, should be generated?
(define (add-bookend {m} [main-talk : (Producer m)] #:when (>= m 400)
                         → (Producer (+ m 600)))
  ;; defines should be after playlist?
  ;; TODO: allow local defines
  ;; (define begin-clip (image circ-png #:length 500))
  ;; (define end-clip (image circ-png #:length 500))
  (let ([begin-clip (image circ-png #:length 500)]
        [end-clip (image circ-png #:length 500)])
    (playlist begin-clip
              (fade-transition #:length 200)
              main-talk
              (fade-transition #:length 200)
              end-clip)))
(check-type add-bookend
            : (→ #:bind {m} (Producer m) (Producer (+ m 600)) #:when (>= m 400)))

; TODO: add filters
(define (attach-audio {n1} [v : (Producer n1)][a : Producer][off : Int]
                      → (Producer n1))
  #;(define cleaned-audio
    (attach-filter
     a
     #;(project-filter #:end off)
     #;(envelope-filter 50 #:direction 'in)
     #;(envelope-filter 50 #:direction 'out)))
  (let ([cleaned-audio (attach-filter a)])
    (multitrack v cleaned-audio #:length (producer-length v))))
(check-type attach-audio
            : (→ #:bind {n} (Producer n) Producer Int (Producer n)))

;; TODO: use define*
(define (conference-talk {n2} [sp : (Producer n2)]
                              [sl : (Producer n2)]
                              [a : Producer]
                              [off : Int]
                              → (Producer (+ n2 600)))
  ;; (define X (add-slides sp sl))
  ;; (define Y (add-bookend X))
  ;; (define v (add-bookend Y))
  (let* ([X (add-slides sp sl)]
         ;[Y (add-bookend X)]
         [v (add-bookend X)])
    (attach-audio v a off)))
(check-type
 conference-talk ; includes inferred constraint
 : (→ #:bind {n} (Producer n) (Producer n) Producer Int (Producer (+ n 600)) #:when (>= n 400)))

(check-type
 (conference-talk (blank 1000) (blank 1000) (color "green") 0)
 : (Producer 1600))

(typecheck-fail
 (conference-talk (blank 200) (blank 200) (color "green") 0)
 #:with-msg
 (add-escs
  "#%app: while applying fn conference-talk;\nfailed condition: (>= n2 400);\ninferred: n2 = 200"))

(check-type (cut-producer (blank 100) #:start 10 #:end 20) : (Producer 10))
(check-type (cut-producer (blank 10) #:start 0 #:end 10) : (Producer 10))

;; start too high
(typecheck-fail
 (cut-producer (blank 9) #:start 10 #:end 20)
 #:with-msg
 (add-escs
  "cut-producer: type mismatch: expected (Producer 20), given (Producer 9)"))
(typecheck-fail
 (cut-producer (blank 9) #:start 8 #:end 20)
 #:with-msg
 (add-escs
  "cut-producer: type mismatch: expected (Producer 20), given (Producer 9)"))
(typecheck-fail
 (cut-producer (blank 9) #:start 6 #:end 5)
 #:with-msg
 (add-escs
  "cut-producer: type mismatch: expected 6, given 5"))

(typecheck-fail
 (cut-producer (color "green" #:length 10) #:start 0 #:end 15)
 #:with-msg
 (add-escs
  "cut-producer: type mismatch: expected (Producer 15), given (Producer 10)"))
(typecheck-fail
 (playlist (blank 10)
           (fade-transition #:length 15)
           (color "green" #:length 10))
 #:with-msg
 (add-escs
  "playlist: transition (fade-transition #:length 15) (334:11) too long for adjacent producer (blank 10) (333:11)"))

(typecheck-fail
 (playlist (blank 15)
           (fade-transition #:length 15)
           (blank 11))
 #:with-msg
 (add-escs
  "playlist: transition (fade-transition #:length 15) (342:11) too long for adjacent producer (blank 11)"))

;;;Copyright (C) 2022 hhs
;;;
;;;Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
;;;to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
;;;and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
;;;
;;;The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
;;;
;;;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;;;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;;;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;;;DEALINGS IN THE SOFTWARE.

(vl-load-com)


(defun p-error-handler (s)
  (if (or (= s "Function cancelled")
	  (= s "quit / exit abort")
	  (= s "������ȡ��")
      )
    (princ)
    (princ s)
  )
  (while (not (equal (getvar "CMDNAMES") "")) (command nil))
  (p-osnap-restore)
  (p-endundomark)
  (p-error-end)
  (princ)
)


(defun p-osnap-disable ()
  ;; �������һ�ε���p-osnap-disableʱ��osmode ֵ
  (if (null $p-saved-osmode)
    (setq $p-saved-osmode (getvar "OSMODE"))
  )
  (if (< $p-saved-osmode 16384)
    (setvar "OSMODE" (+ $p-saved-osmode 16384)) ;_ ���ò�׽
  )
)


(defun p-osnap-restore ()
  (if (not (null $p-saved-osmode))
    (progn
      (setvar "OSMODE" $p-saved-osmode)
      (setq $p-saved-osmode nil)
    )
  )
)


(defun p-startundomark ()
  (if (not $p-undo-started)
    (progn
      (vla-startundomark
	(vla-get-activedocument (vlax-get-acad-object))
      )
      (setq $p-undo-started t)
    )
  )
)


(defun p-endundomark ()
  (if $p-undo-started
    (progn
      (vla-endundomark
	(vla-get-activedocument (vlax-get-acad-object))
      )
      (setq $p-undo-started nil)
    )
  )
)

;;;_$ (p-setvars '((cmdecho . 0)))
;;; (p-setvars '(cmdecho . 0))
;;;((CMDECHO . 1))
(defun p-setvars (pairs / changed name old value)
  (if (atom (car pairs))
    (setq pairs (list pairs))
  )
  (foreach pair	pairs
    (setq name	(car pair)
	  value	(cdr pair)
	  old	(getvar name)
    )
    ;; ���old = nil�������ǵ�ǰCAD�汾��֧�ָñ���
    ;; ��ʱ�����Ա��������޸�
    (if	old
      (progn
	(setq changed (cons (cons name old) changed))
	(setvar name value)
      )
    )
  )
  (reverse changed) ;_ ���ؾ�ֵ�б�
)


(defun p-error-start (vars /)
  (setq $p-sysvars-saved (p-setvars vars))
)


(defun p-error-start0 (/)
  (p-error-start '(("CMDECHO" . 0)))
)


(defun p-error-end ()
  (if $p-sysvars-saved
    (progn
      (p-setvars $p-sysvars-saved)
      (setq $p-sysvars-saved nil)
    )
  )
)


(defun p-commandrun (func / *error*)
  (defun *error* (s)
    (p-error-handler s)
  )

  (p-error-start0)

  (p-startundomark)
  (eval func)
  (p-endundomark)

  (p-error-end)
  (princ)
)

(defun p-commandrun-s (func sysvars / *error*)
  (defun *error* (s)
    (p-error-handler s)
  )

  (p-error-start sysvars)

  (p-startundomark)
  (eval func)
  (p-endundomark)

  (p-error-end)
  (princ)
)

;;; BOOKMARK ��ѧ���





;;; VECTOR



;;;_$ (p-vector-len '(10 10 10))
;;;17.3205
(defun p-vector-len (v /)
  (sqrt (apply '+ (mapcar '* v v)))
)


;;;_$ (p-vector-normal '(10 10 10))
;;;(0.57735 0.57735 0.57735)
(defun p-vector-normal (v / len)
  (setq len (p-vector-len v))
  (if (equal len 0. 1e-6)
    v
    (mapcar (function (lambda (e) (/ e len))) v)
  )
)

(defun p-vector-reverse	(v /)
  (mapcar '- v)
)

;;;;;; �ж϶�ʸ���ķ������:  1 = ͬ��, -1 = ����, 0 = ��ֱ
;;;_$ (p-vector-dotproduct '(1 0 0) '(1 0 0))
;;;1
;;;_$ (p-vector-dotproduct '(1 0 0) '(0 1 0))
;;;0
;;;_$ (p-vector-dotproduct '(1 0 0) '(-1 0 0))
;;;-1
(defun p-vector-dotproduct (v1 v2 /)
  (apply '+ (mapcar '* v1 v2))
)

;;;_$ (p-vector-from2p '(0 0 0) '(1500 1500 0))
;;;(0.707107 0.707107 0.0)
(defun p-vector-from2p (p1 p2 /)
  (p-vector-normal (mapcar '- p2 p1))
)

;;;  ��������λʸ���ļн�, ���ؼнǷ�Χ�� 0 ~ pi/2
;;;_$ (p-vector-angle2 '(1 0 0) '(0 1 0))
;;;1.5708
;;;_$ (p-vector-angle2 '(1 0 0) '(-1 0 0))
;;;0.0
;;;_$ (p-vector-angle2 '(1 0 0) '(1 0 0))
;;;0.0
(defun p-vector-angle2 (v1 v2 / rt)
  (p-acos (p-vector-dotproduct
	    (p-vector-normal v1)
	    (p-vector-normal v2)
	  )
  )
)


;;; ���ض�άʸ����ƽ���еĽǶ�
;;;_$ (p-vector-angle '(1 1))
;;;0.785398
(defun p-vector-angle (v /)
  (atan (cadr v) (car v))
)





;;;(defun sp-angle	(v1 /)
;;;  (atan (cadr v1) (car v1))
;;;)


(defun p-get-bulge (v1 v2 / a1 a2 bulge dot)
  (setq	dot (sp-dotproduct v1 v2)
	a1  (sp-angle v1)
	a2  (sp-angle v2)
  )

  ;;     The bulge factor is used to indicate how much of an arc segment is present at this vertex.
  ;;     The bulge factor is the tangent of one fourth the included angle for an arc segment,
  ;;     made negative if the arc goes clockwise from the start point to the endpoint. A bulge of 0
  ;;     indicates a straight segment, and a bulge of 1 is a semicircle.

  (if (< dot 0)
    (setq bulge (tan (/ (acos (abs dot)) 4.0)))
    (setq bulge (tan (/ (- pi (acos (abs dot))) 4.0)))
  )

  ;; ��ʸ�� V1 (p1 -> p2), V2 (p1 -> pc)һ���� p1 ����ת, ʹ V1 �� X ������һ��, ��ʱ
  ;; V2 �ķ��򼴿�ȷ��͹���������Ǹ�

  (setq a2 (- a2 a1))
  ;; (- a2 a1) ��Ϊ V1 �� X ������һ��ʱ, V2 �� X �����ɵĽǶ� (-pi ~ pi)
  ;; ��ֵΪ��ʱ, ����˳ʱ�뷽����ת, ͹��Ϊ��
  (if (or
	(and (>= a2 0) (< a2 pi))
	(and (< a2 0) (< a2 (- pi)))
      )
    (setq bulge (- bulge))
  )
  bulge
)




(defun p-sqr (f /)
  (* f f)
)


(defun p-acos (f)
  (if (equal f 0. 1e-6)
    (* pi 0.5)
    (atan (/ (sqrt (- 1 (* f f))) f))
  )
)


(defun p-tan (a) (/ (sin a) (cos a)))


(defun p-rad->deg (rad)
  (* 180. (/ rad pi))
)

;;;_$ (p-deg->rad 45)
;;;0.785398
(defun p-deg->rad (deg)
  (* pi (/ deg 180.))
)


(defun p-angle-reverse (a)
  (rem (+ pi a) $2pi)
)

(setq $pi/4  (/ pi 4.)
      $pi/2  (/ pi 2.)
      $pi3/2 (* $pi/2 3.)
      $2pi   (* pi 2.)
      $4pi   (* pi 4.)
)


;; �������Ƕ���-pi/2 ~ pi/2
(defun p-angle-regular (a)
  (if (> a $pi/2)
    (- a pi)
    (if	(< a (- $pi/2))
      (+ a pi)
      a
    )
  )
)

;; �������Ƕ��� 0-2pi
(defun p-angle-normal (a)
  (setq a (rem a $2pi))
  (if (< a 0)
    (setq a (+ a $2pi))
  )
  a
)
;; �����ǵļнǷ���ֵ��Χ 0-pi bug����2012-2-15
;;;_$ (p-angle-include (* 0.5 pi) (* -0.5 pi))
;;;3.14159
;;;_$ (p-angle-include 0 $2pi)
;;;0.0
;;;_$ (p-angle-include -1e-6 $2pi)
;;;1.0e-006
;;;_$ (p-angle-include 1e-6 $2pi)
;;;1.0e-006
;;;_$ (p-angle-include 1e-6 pi)
;;;3.14159
;;;_$ (p-angle-include -1e-6 pi)
;;;3.14159
;;;_$ (p-angle-include 0 pi)
;;;3.14159
(defun p-angle-include (a1 a2 / r)
  (setq r (abs (rem (- a1 a2) $2pi)))
  (if (> r pi)
    (- $2pi r)
    r
  )
)
;;
;;;(defun p-angle-coline (a1 a2 /)
;;;  (setq a (p-angle-include a1 a2))
;;;  (or (equal a pi 1e-3) (equal a 0. 1e-3))
;;;)
;;;_$ (p-ceiling pi 3)
;;;3.142
(defun p-ceiling (f dig / num)
  (setq num (expt 10. dig))
  (/ (fix (+ 0.5 (* f num))) num)
)

;;;_$ (p-round 123.23 50)
;;;150
(defun p-round (f num /)
  (fix (- f (rem f num) (- num)))
)


(defun p-mid (p1 p2 / e)
  (mapcar (function (lambda (e) (/ e 2.)))
	  (mapcar (function +) p1 p2)
  )
)


(defun p-hash-1	(e h /)
  (+ (fix e) (* 31 h))
)
;;;_$ (p-hash '(1 2 3))
;;;838715010
;;;_$ (p-hash 1)
;;;-477111343
(defun p-hash (lst /)
  (setq h (getvar 'millisecs))
  (if (atom lst)
    (setq h (p-hash-1 lst h))
    (foreach e lst
      (setq h (p-hash-1 e h))
    )
  )
)
;;;_$ (p-uid)
;;;144664381
(defun p-uid (/)
  (if (null $p-uid-base)
    (setq $p-uid-base 1)
  )

  (setq $p-uid-base (abs (p-hash-1 (getvar 'millisecs) $p-uid-base)))
)


;;;-----------------------------------------------------------;;
;;; p-mxm Multiply two matrices -Vladimir Nesterovsky-      ;;
;;;-----------------------------------------------------------;;
(defun p-mxm (m q)
  (mapcar '(lambda (r) (p-mxv (p-trp q) r)) m)
)

;;;-----------------------------------------------------------;;
;;; Matrix x Vector - Vladimir Nesterovsky                    ;;
;;; Args: m - nxn matrix, v - vector in R^n                   ;;
;;;-----------------------------------------------------------;;
(defun p-mxv (m v)
  (mapcar '(lambda (r) (apply '+ (mapcar '* r v)))
	  m
  )
)

;;; p-trp Transpose a matrix -Doug Wilson-                  ;;
;;;-----------------------------------------------------------;;
(defun p-trp (m)
  (apply 'mapcar (cons 'list m))
)

;;;-----------------------------------------------------------;;
;;; p-RefGeom (gile)                                        ;;
;;; Returns a list which first item is a 3x3 transformation   ;;
;;; matrix(rotation,scales normal) and second item the object ;;
;;; insertion point in its parent(xref, bloc or space)        ;;
;;;                                                           ;;
;;; Argument : an ename                                       ;;
;;;-----------------------------------------------------------;;
(defun p-refgeom (ename / elst ang norm mat)
  (setq	elst (entget ename)
	ang  (cdr (assoc 50 elst))
	norm (cdr (assoc 210 elst))
  )
  (list
    (setq mat
	   (p-mxm
	     (mapcar (function (lambda (v) (trans v 0 norm t)))
		     '((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))
	     )
	     (p-mxm
	       (list (list (cos ang) (- (sin ang)) 0.0)
		     (list (sin ang) (cos ang) 0.0)
		     '(0.0 0.0 1.0)
	       )
	       (list (list (cdr (assoc 41 elst)) 0.0 0.0)
		     (list 0.0 (cdr (assoc 42 elst)) 0.0)
		     (list 0.0 0.0 (cdr (assoc 43 elst)))
	       )
	     )
	   )
    )
    (mapcar
      '-
      (trans (cdr (assoc 10 elst)) norm 0)
      (p-mxv mat
	     (cdr (assoc 10 (tblsearch "BLOCK" (cdr (assoc 2 elst)))))
      )
    )
  )
)


;;; ����ָ��ʵ���ڵĵ��WCS����ֵ
;;; p �鶨���ڵĵ�
;;; insert ��ʵ��ͼԪ
(defun p-block-trans (p geom /)
  (mapcar '+ (p-mxv (car geom) p) (cadr geom))
)

;; �鶨���еĶ��� �������Զ���
;; (p-block-items "A$C3CA026BF")
;; (mapcar '(lambda (e) (p-dxf e 0)) (p-block-items "A$C3CA026BF"))
;; ("SEQEND" "ATTRIB" "LWPOLYLINE" "LWPOLYLINE" "TEXT" "ATTDEF" "LWPOLYLINE" "LWPOLYLINE")
(defun p-block-items-inner (en / name r)
  (if (= 'str (type en))
    (setq en (tblobjname "block" en))
  )
  (while (setq en (entnext en))
    (if	(= "INSERT" (p-dxf en 0))
      (progn
	(setq name (p-dxf en 2))
	(if (not (member name $p-block-walked))
	  (setq	r		(append r (p-block-items name))
		$p-block-walked	(cons name $p-block-walked)
	  )
	)
      )
      (setq r (cons en r))
    )
  )
  r
)
(defun p-block-items (en /)
  (setq $p-block-walked nil)
  (p-block-items-inner en)
)
;; (p-insert-seqs (car (entsel)))
;; �������еĶ��� ��Ҫ�Ǹ�ʵ�������Ե�
(defun p-insert-seqs (en / r)
  (while (and (setq en (entnext en))
	      (/= "SEQEND" (p-dxf en 0))
	 )
    (setq r (cons en r))
  )
  r
)

;;; BOOKMARK ���󴴽�

;;(p-item (vla-get-layouts (vla-get-activedocument (vlax-get-acad-object))) "1" )
(defun p-item (obj name / r)
  (if (vl-catch-all-error-p
	(setq r (vl-catch-all-apply 'vla-item (list obj name)))
      )
    nil
    r
  )
)




;;; BOOKMARK - LAYER ͼ�����

;;; (p-layer-get1 "0" nil)
;;; ((0 . "LAYER") (2 . "0") (70 . 0) (62 . 7) (6 . "Continuous"))
;;;_$ (p-layer-get1 "3" nil)
;;;((0 . "LAYER") (100 . "AcDbSymbolTableRecord") (100 . "AcDbLayerTableRecord") (70 . 0) (6 . "Continuous") (62 . 7) (370 . -3) (2 . "3"))
;;;_$ (p-layer-get1 "2" '((62 . 2) (290 . 0)))
;;;((0 . "LAYER") (100 . "AcDbSymbolTableRecord") (100 . "AcDbLayerTableRecord") (70 . 0) (6 . "Continuous") (62 . 2) (370 . -3) (2 . "2") (290 . 0))
(defun p-layer-get1 (name dxf / r)
  (setq r (tblsearch "LAYER" name))
  (if (null r)
    (setq r (entmake (p-set (list '(0 . "LAYER")
				  '(100 . "AcDbSymbolTableRecord")
				  '(100 . "AcDbLayerTableRecord")
				  '(70 . 0) ;_ status on/off lock freeze
				  '(6 . "Continuous")
				  '(62 . 7) ;_ color
				  '(370 . -3) ;_ linewidth
				  (cons 2 name)
			    )
			    dxf
		     )
	    )
    )
  )
  r
)
;; ȷ��ָ��ͼ����ڲ����أ�������ʱʹ��conf��������ͼ��Ĵ���
;;;(defun p-layer-get (name conf / layer layers)
;;;  (setq layers (vla-get-layers (vla-get-activedocument (vlax-get-acad-object))))
;;;  
;;;  (if (vl-catch-all-error-p
;;;	(setq layer
;;;	       (vl-catch-all-apply
;;;		 'vla-item
;;;		 (list layers name)
;;;	       )
;;;	)
;;;      )
;;;    (progn
;;;      (setq layer (vla-add layers name))
;;;
;;;      (vl-catch-all-apply 'vla-put-color (list layer (car conf)))
;;;
;;;      (p-linetype-get (cadr conf))
;;;      (vl-catch-all-apply 'vla-put-linetype (list layer (cadr conf)))
;;;      
;;;      (vl-catch-all-apply 'vla-put-lineweight (list layer (* 100 (atof (caddr conf)))))
;;;      
;;;      (if (and (not (null (nth 3 conf)))
;;;	       (= "FALSE" (strcase (nth 3 conf)))
;;;	  )
;;;	(vl-catch-all-apply 'vla-put-plottable (list layer :vlax-false))
;;;      )
;;;      
;;;      (vl-catch-all-apply 'vla-put-description (list layer (nth 4 conf)))
;;;      ;;(vl-catch-all-apply 'vla-put-plotstylename (list layer (nth 4 conf)))
;;;    )
;;;  )
;;;  layer
;;;)
(defun p-layer-get (name conf / dxf layer)
  (if (null (setq layer (tblsearch "LAYER" name)))
    (progn
      (setq dxf	(list '(0 . "LAYER")
		      '(100 . "AcDbSymbolTableRecord")
		      '(100 . "AcDbLayerTableRecord")
		      '(70 . 0)
		      '(6 . "Continuous")
		      (cons 2 name)
		)
      )

      (if (car conf)
	(setq dxf (append dxf (list (cons 62 (atoi (car conf))))))
      )

      (if (cadr conf)
	(progn
	  (p-linetype-get (cadr conf))

	  (setq dxf (append dxf (list (cons 6 (cadr conf)))))
	)
      )

      (if (caddr conf)
	(setq dxf (append dxf (list (cons 370 (atoi (caddr conf))))))
      )

      (if (and (not (null (cadddr conf)))
	       (= "FALSE" (strcase (cadddr conf)))
	  )
	(setq dxf (append dxf (list (cons 290 0))))
      )

      (entmake dxf)
    )
    layer
  )
)




;;;  (entmake (list '(0 . "LTYPE") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbLinetypeTableRecord") (cons 2 "BERDIG 5-545") '  (3 . "Border ____   ____   ____   ____   ____") '(70 . 0) '(73 . 2) '(40 . 15.0) '(49 . 10.0) '(74 . 0) '
;;;   (49 . -5.0) '(74 . 0)    ) )

;; ȷ��ָ�����ʹ��ڲ�����
(defun p-linetype-get	(name / lt)
  (setq	lt
	 (vl-catch-all-apply
	   'vla-item
	   (list (vla-get-linetypes
		   (vla-get-activedocument (vlax-get-acad-object))
		 )
		 name
	   )
	 )
  )
  (if (vl-catch-all-error-p lt)
    (setq lt (p-linetype-load name "acad.lin"))
  )
  lt
)

;;; (p-linetype-load "CENTERX2" "ACAD.lin")
(defun p-linetype-load (name filename /)
  (vla-load (vla-get-linetypes
	      (vla-get-activedocument (vlax-get-acad-object))
	    )
	    name
	    filename
  )
)

;; ȷ��ָ��������ʽ���ڲ�����
;;; (p-textstyle-get "1" "simplex8.shx" "hztxt.shx")
(defun p-textstyle-get (name font bigfont width / style styles)
  (setq	styles (vla-get-textstyles
		 (vla-get-activedocument (vlax-get-acad-object))
	       )
  )
  (if (vl-catch-all-error-p
	(setq style
	       (vl-catch-all-apply
		 'vla-item
		 (list styles name)
	       )
	)
      )
    (progn
      (setq style (vla-add styles name))
      (vla-put-fontfile style font)
      (vla-put-bigfontfile style bigfont)
      (vla-put-width style width)
    )
  )
  style
)

(defun p-get-block (name /)
  (vl-catch-all-apply
    'vla-item
    (list (vla-get-blocks
	    (vla-get-activedocument (vlax-get-acad-object))
	  )
	  name
    )
  )
)

(setq $addnew-default '("0" 256 "BYLAYER" -1 "Standard" (0 0 0)))
;;;  $addnew-layer	     "0"
;;;  $addnew-color	     256 ;_ 0 ByBlock 256 ByLayer
;;;  $addnew-linetype   "BYLAYER"
;;;  $addnew-lineweight -1 ;_ -1 ByLayer -2 ByBlock -3 Ĭ��
;;;  $addnew-textstyle  "Standard"
;;;  $addnew-block-base '(0. 0. 0.)

(defun p-set-symbol-notnull (sym val /)
  (if val
    (set sym val)
  )
)
(defun p-make-setenv (vars / rv)
  (setq	rv (list $addnew-layer		 $addnew-color
		 $addnew-linetype	 $addnew-lineweight
		 $addnew-textstyle	 $addnew-block-base
		)
  )
  (p-set-symbol-notnull '$addnew-layer (car vars))
  (p-set-symbol-notnull '$addnew-color (cadr vars))
  (p-set-symbol-notnull '$addnew-linetype (caddr vars))
  (p-set-symbol-notnull '$addnew-lineweight (cadddr vars))
  (p-set-symbol-notnull
    '$addnew-textstyle
    (car (cddddr vars))
  )
  (p-set-symbol-notnull
    '$addnew-block-base
    (cadr (cddddr vars))
  )
  rv
)

(p-make-setenv $addnew-default)


;; ����ʵ��ָ������ֵ
;; (p-entmod (car (entsel)) '((62 . 1) (370 . 13)))
;; (p-entmod (car (entsel)) '(62 . 7))
(defun p-entmod	(ent datas /)
  (entmod (p-set (entget ent) datas))
)


;; Ĭ�϶��󴴽��߼�
(defun p-entmake (dxf / r)
;;;(if $p-user-block (entmake '((0 . "ENDBLK"))))
  (p-linetype-get $addnew-linetype)

;;;  (setq	r (vl-catch-all-apply
;;;	    'entmakex
;;;	    (list (append dxf
;;;			  (list	(cons 8 $addnew-layer)
;;;				(cons 6 $addnew-linetype)
;;;				(cons 62 $addnew-color)
;;;				(cons 370 $addnew-lineweight)
;;;			  )
;;;		  )
;;;	    )
;;;	  )
;;;  )
  ;; code above dosn't work in cad2008 make insert returns ename 0
  (vl-catch-all-apply
    'entmakex
    (list (append dxf
		  (list	(cons 8 $addnew-layer)
			(cons 6 $addnew-linetype)
			(cons 62 $addnew-color)
			(cons 370 $addnew-lineweight)
		  )
	  )
    )
  )
  (setq r (entlast))

  (if (null (vl-catch-all-error-p r))
    (if	$addnew-xdata
      (p-xdata-set
	r
	(car $addnew-xdata)
	(cdr $addnew-xdata)
      )
    )
  )
  r
)
;;;  ����ֱ�� (p-make-line (getpoint) (getpoint))
(defun p-make-line (p1 p2 /)
  (p-entmake (list
	       '(0 . "LINE")
	       (cons 10 p1)
	       (cons 11 p2)
	     )
  )
)
;;;  ����Բ (p-make-circle (getpoint) 100.)
(defun p-make-circle (center radius /)
  (p-entmake (list
	       '(0 . "CIRCLE")
	       (cons 10 center)
	       (cons 40 radius)
	     )
  )
)
;;;  ����Բ�� (p-make-arc (getpoint) 100. 0 (/ pi 2.))
(defun p-make-arc (point radius start end /)
  (p-entmake (list
	       '(0 . "ARC")
	       (cons 10 point)
	       (cons 40 radius)
	       (cons 50 start)
	       (cons 51 end)
	     )
  )
)
;; ʼ������С��С��180d��Բ��
(defun p-make-sharparc (p r a4 a5)
  (if (or (and (> a5 a4) (< (- a5 a4) pi))
	  (and (< a5 a4) (> (- a4 a5) pi))
      )
    (p-make-arc p r a4 a5)
    (p-make-arc p r a5 a4)
  )
)
;;
;; (p-make-ellipse (setq p (getpoint)) (mapcar '- (getpoint p) p) 0.4)
(defun p-make-ellipse (p1 p2 r1)
  (p-entmake (list '(0 . "ELLIPSE")
		   '(100 . "AcDbEntity")
		   '(100 . "AcDbEllipse")
		   (cons 10 p1)
		   (cons 11 p2)
		   (cons 40 r1)
		   (cons 41 0.)
		   '(42 . 6.28319)
	     )
  )
)
;;; ���ɶ���� (p-make-polyline (list (getpoint) (getpoint) (getpoint)) 1 20.)
(defun p-make-polyline (points closed width / e)
  (p-entmake (append
	       (list '(0 . "LWPOLYLINE")
		     '(100 . "AcDbEntity")
		     '(100 . "AcDbPolyline")
		     (cons 90 (length points))
		     (cons 70 closed)
		     (cons 43 width)
	       )
	       (mapcar '(lambda (e) (cons 10 e)) points)
	     )
  )
)
;;; ���ɵ������� (p-make-text "123456" (getpoint) "C" 4. 0.7 0.)
(defun p-make-text (text point align height width ang / c)
  (p-textstyle-get
    $addnew-textstyle
    "gbenor.shx"
    "hztxt.shx"
    0.7
  )

  (setq	c (cdr (assoc (strcase align)
		      '(("L" 0 0)
			("C" 1 0)
			("R" 2 0)
			("A" 3 0)
			("M" 4 3)
			("F" 5 0)
			("TL" 0 3)
			("TC" 1 3)
			("TR" 2 3)
			("ML" 0 2)
			("MC" 1 2)
			("MR" 2 2)
			("BL" 0 1)
			("BC" 1 1)
			("BR" 2 1)
		       )
	       )
	  )
  )
  (p-entmake
    (list '(0 . "TEXT")
	  (cons 1 text)
	  (cons 7 $addnew-textstyle)
	  (cons 10 point)
	  (cons 11 point)
	  (cons 40 height)
	  (cons 41 width)
	  (cons 50 ang)
	  (cons 72 (car c))
	  (cons 73 (cadr c))
    )
  )
)

;;; ���ɿ�
;;; (p-make-block "*U" '(lambda () (p-make-line '(0 0 0) '(10 0 0)) (p-make-circle '(0 0 0) 10.)) nil)
;;; (setq p '(0 0) r 13.)
;;; (p-make-block "C13" 'p-make-circle (list p r))
(defun p-make-block (name funcname params / en r)
  (entmake
    (list
      (cons 0 "BLOCK")
      (cons 2 name)
      (cons 70
	    (if	(= "*U" name)
	      1
	      0
	    )
      )
      (cons 10 $addnew-block-base)
    )
  )

  (setq r (vl-catch-all-apply funcname params))
  (setq en (entmake '((0 . "ENDBLK"))))

  (if (vl-catch-all-error-p r)
    (progn
      (princ (strcat "\nerror in p-make-block:"
		     (vl-princ-to-string (cons funcname params))
	     )
      )
      nil
    )
    en
  )
)
;;; ���ɿ���� (p-make-insert "*U8" (getpoint) 1 1 1 0)
(defun p-make-insert (name point sx sy sz ang)
  (p-entmake (list '(0 . "INSERT")
		   (cons 2 name)
		   (cons 10 point)
		   (cons 41 sx)
		   (cons 42 sy)
		   (cons 43 sz)
		   (cons 50 ang)
	     )
  )
)
;;; ���ɿ鲢����˿����
;;; (p-make-insert-with-funcs "*U" (getpoint) 'p-make-circle '((0 0 0) 10.))
;;; (p-make-insert-with-funcs "*U" (getpoint) '(lambda () (p-make-circle '(0 0 0) 13.) (p-make-circle '(0 0 0) 10.)) nil)
;;; (p-make-insert-with-funcs "*U" (getpoint) 'p-make-circle (p-get-params '(a b) '((a 0 0 0) (b . 10.))))
;;; (p-make-insert-with-funcs "*U" (getpoint) 'd-user-draw-gate-valve-fr '(300 200 150 500))
;;; (p-make-insert-with-funcs "*U" (getpoint) 'd-user-draw-duct-up (p-get-params '(FLANGEDIAMETER LENGTH) (p-xprop-get-from-csvfile "/size/flange pn.csv" "FL-PL-2.5-15" '(FlangeDiameter Length))))
;;;(defun p-make-insert-with-funcs	(name point funcname params /)
;;;  (setq name (p-make-block name point funcname params))
;;;  (p-make-insert name point 1. 1. 1. 0.)
;;;)
(defun p-make-insert-with-funcs	(name point funcname params /)
  ;;(setq $addnew-block-base point)
  (setq name (p-make-block name funcname params))
  ;;(setq $addnew-block-base '(0 0 0))
  (p-make-insert name point 1. 1. 1. 0.)
)
(defun p-make-insert-with-funcs-a
       (name point funcname params sx sy sz ang /)
  ;;(setq $addnew-block-base point)
  (setq name (p-make-block name funcname params))
  ;;(setq $addnew-block-base '(0 0 0))
  (p-make-insert name point sx sy sz ang)
)
;;; ���ݲ����������Ա����ɲ����� (p-get-params '(Length FlangeDiameter) '((FlangeDiameter . 80) (Length . 12)))
;;;(defun p-get-params (pnames property / params)
;;;  (foreach e pnames
;;;    (if	(vl-symbolp e)
;;;      (setq params (cons (cdr (assoc e property)) params))
;;;      (setq params (cons e params))
;;;    )
;;;  )
;;;  (reverse params)
;;;)
;;;(p-xprop-get-from-csvfile "/size/flange pn.csv" "FL-PL-2.5-15" '(FlangeDiameter Length))
;;;(p-insert-with-property (getpoint) "*U" '(p-user-draw-duct-up width height) (p-xprop-getall-s (car (entsel)) "MYPROPS_ROUTER"))








(defun p-ensure-object (obj)
  (if (= 'ename (type obj))
    (vlax-ename->vla-object obj)
    obj
  )
)

(defun p-ensure-ename (obj)
  (if (/= 'ename (type obj))
    (vlax-vla-object->ename obj)
    obj
  )
)


;;;  ������list��ת
;;;_$ (p-var->list (p-list->var '(1 2 3 (4 5 6))))
;;;(1 2 3 (4 5 6))
(defun p-var->list (var / e)
  (cond
    ((= 'safearray (type var))
     (mapcar '(lambda (e) (p-var->list e))
	     (vlax-safearray->list var)
     )
    )
    ((= 'variant (type var))
     (p-var->list (vlax-variant-value var))
    )
    (t
     var
    )
  )
)
(defun p-list->var (lsp / e n var)
  (if (vl-consp lsp)
    (progn
      (setq n	(1- (length lsp))
	    var	(vlax-make-safearray vlax-vbvariant (cons 0 n))
      )
      (vlax-safearray-fill
	var
	(mapcar '(lambda (e) (p-list->var e)) lsp)
      )
      var
    )
    (vlax-make-variant lsp)
  )
)




;;; ARRAY ����

(defun p-array-create (n /)
  (vlax-make-safearray vlax-vbvariant (cons 0 n))
)


(defun p-array-set (arr n value /)
  (vlax-safearray-put-element arr n (p-list->var value))
)


(defun p-array-get (arr n /)
  (p-var->list (vlax-safearray-get-element arr n))
)



;;; BOOKMARK - ��չ����(XDATA)������XDATA�����Թ���


;; (p-xdata-get-inner (car (entsel)) "KTGX")
;; (("KTGX" (1002 . "{") (1070 . 2) (1000 . "M-�ͷ�-���") (1002 . "}")))
;; (p-xdata-get-inner (car (entsel)) "*")
;; (("KTGX" (1002 . "{") (1070 . 2) (1000 . "M-�ͷ�-���") (1002 . "}")) ("TFGX" (1002 . "{") (1000 . "(\"R\" 400 400 3000.00 3000.00 \"M\" 0.00)") (1002 . "}")) ...))
;; (p-xdata-get-inner (car (entsel)) "KTGX,TFGX")
;; (("KTGX" (1002 . "{") (1070 . 2) (1000 . "M-�ͷ�-���") (1002 . "}")) ("TFGX" (1002 . "{") (1000 . "(\"R\" 400 400 3000.00 3000.00 \"M\" 0.00)") (1002 . "}")))
;; ���� appname Ϊ"*"��������Ӧ�����Ƶ���չ���ݻ򷵻�ָ��Ӧ��������չ����
(defun p-xdata-get-inner (ename appname /)
  ;;  (vla-getxdata (p-ensure-object obj) appname 'xtypeout 'xdataout)
  ;;  (if xtypeout
  ;;    (mapcar '(lambda (a b) (cons a b))
  ;;	    (vlax-safearray->list xtypeout)
  ;;	    (mapcar '(lambda (e)
  ;;		       (if (>= (vlax-variant-type e) 8192)
  ;;			 (vlax-safearray->list (vlax-variant-value e)) ;_ �㼰ʸ��
  ;;			 (vlax-variant-value e) ;_ str int real��������
  ;;		       )
  ;;		     )
  ;;		    (vlax-safearray->list xdataout)
  ;;	    )
  ;;    )
  ;;  )
  ;;  "Benchmark loops = 10000, in 2281 ms, 4384 invoke / s"
  ;; ��Ϊ�������� ���������д��
  ;;  "Benchmark loops = 10000, in 422 ms, 23697 invoke / s"
  (cdr (assoc -3 (entget ename (list appname))))
)

;; _$ (p-xdata-get en "BMZ")
;; ((1002 . "{") (1040 . 0.0) (1002 . "}"))
(defun p-xdata-get (ename appname /)
  (cdar (p-xdata-get-inner ename appname))
)
;;;(defun p-xdata-set (obj xdata / e appname n datatype data)
;;;  ;; �Զ�ע��Ӧ������
;;;  (setq appname (cdr (assoc 1001 xdata)))
;;;  (if (null (tblsearch "APPID" appname))
;;;    (regapp appname)
;;;  )
;;;
;;;  (setq	n	 (1- (length xdata))
;;;	datatype (vlax-make-safearray vlax-vbinteger (cons 0 n))
;;;	data	 (vlax-make-safearray vlax-vbvariant (cons 0 n))
;;;  )
;;;  (vlax-safearray-fill datatype (mapcar 'car xdata))
;;;  (vlax-safearray-fill
;;;    data
;;;    (mapcar '(lambda (e)
;;;	       (if (listp e)
;;;		 (vlax-3d-point e)
;;;		 e
;;;	       )
;;;	     )
;;;	    (mapcar 'cdr xdata)
;;;    )
;;;  )
;;;  (vla-setxdata (p-ensure-object obj) datatype data)
;;;)
;; (p-xdata-set-inner (car (entsel)) '(("A" (1000 . "A"))("B" (1000 . "B"))))
(defun p-xdata-set-inner (ename xdata /)
;;;    (append (entget ename) (list (list -3 (cons appid xdata))))
  (entmod (list (cons -1 ename) (cons -3 xdata)))
)
;; (p-xdata-set (car (entsel)) "KTGX" '((1040 . 2.33)))
(defun p-xdata-set (ename appid xdata /)
  (if (null (tblsearch "APPID" appid))
    (regapp appid)
  )

  (p-xdata-set-inner ename (list (cons appid xdata)))
)


;(p-xdata-all (car (entsel)))
(defun p-xdata-all (ename /)
  (p-xdata-get-inner ename "*")
)

;; (p-xdata-keys (car (entsel)))
;; ("TFGX" "GXFL" "GXFS" "BMZ" "SS" "YCSS" ...)
(defun p-xdata-keys (ename /)
  (mapcar 'car (p-xdata-all ename))
)

(defun p-xdata-exist (ename key /)
  (member key (p-xdata-keys ename))
)


;;; �Ƴ�ָ��Ӧ������
;; (p-xdata-remove (car (entsel)) "KTGX")
;; (p-xdata-remove (car (entsel)) '("KTGX" "TFGX"))
;;;_$ (p-xdata-remove (car (entsel)) "*")
;;;_$ (p-xdata-keys(car (entsel)) )
;;;nil
(defun p-xdata-remove (ename appid /)
  (cond	((= "*" appid)
	 (p-xdata-set-inner
	   ename
	   (mapcar 'list (p-xdata-keys ename))
	 )
	)
	((listp appid)
	 (p-xdata-set-inner ename (mapcar 'list appid))
	)
	(t
	 (p-xdata-set-inner ename (list (cons appid nil)))
	)
  )
)




;;; ֧�������������������ݵ���չ���ݹ���

;; ��ȡָ��������ֵ
;; (p-xprop-get (car (entsel)) "PSK-FIT" "W")
;; 1000.
;; (p-xprop-get (car (entsel)) "PSK-FIT" '("H" "W"))
;; (("H" . 400) ("W" . 1000))
(defun p-xprop-get (ename appname names / xdata rv)
  (setq xdata (p-xdata-get ename appname))
  (cond
    ((atom names)
     (while xdata
       (if (= names (cdar xdata))
	 (setq rv    (cdadr xdata)
	       xdata nil
	 )
       )
       (setq xdata (cddr xdata))
     )
    )
    ((vl-consp names)
      (while xdata
	(if (member (cdar xdata) names)
	  (setq	rv    (cons (cons (cdar xdata) (cdadr xdata)) rv)
		names (vl-remove (cdar xdata) names)
	  )
	)
	(setq xdata (cddr xdata))
      )
    )
  )
  rv
)
;;


(defun p-xprop-unpack (xdata / rv)
  (while xdata
    ;; ����������Ƽ�ֵ
    (setq rv	(cons (cons (cdar xdata) (cdadr xdata)) rv)
	  xdata	(cddr xdata)
    )
  )
  (reverse rv)
)

;;; ��ȡָ��Ӧ�����µ��������Թ����б�
;;; (p-xprop-getall (car (entsel)) "MYPROPS_ROUTER")
;;; (("W" . 1000) ("H" . 400) ("SERV" . "EA(SE)") ...)
(defun p-xprop-getall (ename appname / )
  (p-xprop-unpack (p-xdata-get ename appname))
)


;; ��������תΪ����
;;; (p-xprop-getall-s (car (entsel)) "MYPROPS_ROUTER")
;;; ((WIDTH . 1000) (HEIGHT . 400) (SERVICE . "EA(SE)") ...)
;;;(defun p-xprop-getall-s (ename appname / e props)
;;;  (setq	props (p-xprop-getall ename appname)
;;;	props (mapcar '(lambda (e)
;;;			 (cons (read (vl-string-trim " ." (car e))) (cdr e))
;;;		       )
;;;		      props
;;;	      )
;;;  )
;;;)


;;; (p-xprop-exist (car (entsel)) "MYPROPS_ROUTER" '("P1" "P2"))
;;; (p-xprop-exist (car (entsel)) "MYPROPS_ROUTER" "P1")
(defun p-xprop-exist (ename appname names / rv)
  (setq rv (p-xprop-get ename appname names))
  (cond
    ((atom names)
     rv
    )
    ((vl-consp names)
     (= (length names) (length rv))
    )
  )
)
;;



;; ������һ��������ĵ�һ���ԣ��Ա���xdata�б���
;;;_$ (p-xprop-pack1 '("P1" . 2) nil)
;;;((1000 . "P1") (1070 . 2))
;;;_$ (p-xprop-pack1 '("P1" . 2) '(("P1" . 1013)))
;;;((1000 . "P1") (1013 . 2))
(defun p-xprop-pack1 (kv xdatatypes / code name value)
  (setq	name  (car kv)
	value (cdr kv)
  )
  (or (setq code (cdr (assoc name xdatatypes)))
      ;; ��δ�ṩ������������ʱ������Ĭ����������
      (setq code
	     (cdr
	       (assoc (type value)
		      '((str . 1000) (int . 1070) (real . 1040) (list . 1010))
	       )
	     )
      )
  )

  (list (cons 1000 name) (cons code value))
)

(defun p-xprop-pack (properties xdatatypes / enc rv)
  (foreach e properties
    (setq enc (p-xprop-pack1 e xdatatypes))
    (setq rv (cons (car enc) rv)
	  rv (cons (cadr enc) rv)
    )
  )
  (reverse rv)
)


(defun p-xprop-replace (ename appname prop datadef / xdata xdata2 tmp)
  (if (atom (car prop))
    (setq prop (list prop))
  )

  (p-xdata-set ename appname (p-xprop-pack prop datadef))
)
;;; �ɶ�һ���򼸸����Ե����������ã��Ѵ��ڵ��������Բ���Ӱ��
;;; ������������datadef��ָ��
;;; (p-xprop-set-inner (car (entsel)) "MYPROPS_ROUTER" '("A" . 30) '(("A" . 1040)))
;;; (p-xprop-set-inner (car (entsel)) "MYPROPS_ROUTER" '("A" . 30) nil)
;;; (p-xprop-set-inner (car (entsel)) "MYPROPS_ROUTER" '(("A" . 800) ("B" . 400)) nil)
;; TODO: ��������ݷǵ�Ա�ʱ ���ؽ������
(defun p-xprop-set-inner
       (ename appname prop datadef / xdata xdata2 tmp)
  (if (atom (car prop))
    (setq prop (list prop))
  )
  (setq	prop (vl-remove-if
	       '(lambda	(e)
		  (or (null (car e))
		      (= "" (car e))
		      (null (cdr e))
		      (vl-catch-all-error-p (cdr e))
		  )
		)
	       prop
	     )
  ) ;_ ȥ����Ч����������

  (if prop
    (progn
      (setq xdata (p-xdata-get ename appname))
      (while xdata
	(if (setq tmp (assoc (cdar xdata) prop))
	  (setq	xdata2 (cons (car xdata) xdata2)
		xdata2 (cons (cons (caadr xdata) (cdr tmp)) xdata2)
		prop   (vl-remove tmp prop)
	  )
	  (setq	xdata2 (cons (car xdata) xdata2)
		xdata2 (cons (cadr xdata) xdata2)
	  )
	)
	(setq xdata (cddr xdata))
      )
      (if prop
	(foreach e prop
	  (setq
	    xdata2 (append
		     (reverse
		       (p-xprop-pack1 e datadef)
		     )
		     xdata2
		   )
	  )
	)
      )
      (setq xdata2 (reverse xdata2))
      (p-xdata-set ename appname xdata2)
    )
  )
)
;;

(defun p-xprop-set (ename appname prop /)
  (p-xprop-set-inner ename appname prop nil)
)
;;; (p-xprop-remove (car (entsel)) "MYPROPS_ROUTER" "P1")
(defun p-xprop-remove (ename appname names / xdata xdata2)
  (if (and names (atom names))
    (setq names (list names))
  )

  (if names
    (progn
      (setq xdata (p-xdata-get ename appname))
      (while xdata
	(if (member (cdar xdata) names)
	  (setq names (vl-remove (cdar xdata) names))
	  (setq	xdata2 (cons (car xdata) xdata2)
		xdata2 (cons (cadr xdata) xdata2)
	  )
	)
	(setq xdata (cddr xdata))
      )

      (setq xdata2 (reverse xdata2))
      (p-xdata-set ename appname xdata2)
    )
  )
)


;;; BOOKMARK ��������������

;;; ��ȡ�û��������ֵ
(defun p-edit-value (msg old / value)
  (cond
    ((= 'real (type old))
     (setq value (getdist (strcat msg " <" (rtos old 2 2) ">: ")))
    )
    ((= 'int (type old))
     (setq value (getint (strcat msg " <" (itoa old) ">: ")))
    )
    ((= 'list (type old))
     (setq
       value
	(getpoint (strcat msg " <" (vl-princ-to-string old) ">: "))
     )
    )
    ((= 'str (type old))
     (setq value (getstring (strcat msg " <" old ">: ")))
    )
  )
  (if (or (null value) (= "" value))
    old
    value
  )
)

(defun p-getdist (msg old p / value)
  (if p
    (setq value (getdist (strcat msg " <" (rtos old 2 2) ">: ") p))
    (setq value (getdist (strcat msg " <" (rtos old 2 2) ">: ")))
  )

  (if (null value)
    old
    value
  )
)


(defun p-confirm (msg default / r)
  (initget "Y N ")
  (if (null (setq r (getkword (strcat msg " [��(Y)/��(N)] <" default ">:"))))
    (setq r default)
  )
  r
)

(defun p-getkword (msg kword default / r)
  (initget kword)
  (if (null (setq r (getkword (strcat msg " <" default ">: "))))
    default
    r
  )
)
;; (p-getkword1 "ѡ��" '(("A" "OPTIONA") ("B" "OPTIONB") ("C" "OPTIONC")) "A")
(defun p-getkword1 (msg kwords default / r)
  (initget (p-string-connect (mapcar 'car kwords) " "))
  (setq	r (getkword (strcat msg
			    " ["
			    (p-string-connect
			      (mapcar
				(function
				  (lambda (e)
				    (strcat (cadr e) "(" (car e) ")")
				  )
				)
				kwords
			      )
			      "/"
			    )
			    "] <"
			    default
			    ">: "
		    )
	  )
  )
  (if (null r)
    default
    r
  )
)
(defun p-getint	(msg init default / r)
  (if init
    (initget init)
  )

  (if (null (setq r (getint (strcat msg " <" (itoa default) ">")))
      )
    default
    r
  )
)

;;;_$ (p-string-empty? nil)
;;;T
;;;_$ (p-string-empty? "")
;;;T
;;;_$ (p-string-empty? "sd")
;;;nil
(defun p-string-empty? (v)
  (or (null v) (= "" v))
)

(defun p-stringp (v)
  (= 'str (type v))
)


;; (p-string-subst "112233" "1" "21")
;; "21212233"
(defun p-string-subst (str find repl / pos len)
  (setq	len (strlen repl)
	pos 0
  )
  (while (setq pos (vl-string-search find str pos))
    (setq str (vl-string-subst repl find str pos)
	  pos (+ pos len)
    )
  )
  str
)
;;;_$ (p-string-substp "K02-22 222" "22" "*" 0)
;;;"K02-22 222"
;;;_$ (p-string-substp "K02-22 222" "22" "*" 1)
;;;"K02-* 222"
;;;_$ (p-string-substp "K02-22 222" "22" "*" 2)
;;;"K02-22 *2"
;;;_$ (p-string-substp "K02-22 222" "22" "*" 3)
;;;"K02-22 222"
(defun p-string-substp (str find repl p / pos len)
  (setq	len (strlen find)
	pos 0
	occ 0
  )
  (while (and (setq pos (vl-string-search find str pos))
	      (< (setq occ (1+ occ)) p)
	 )
    (setq pos (+ pos len))
  )
  (if (= occ p)
    (vl-string-subst repl find str pos)
    str
  )
)
;;

;;;_$ (p-string-connect '("1" "2" "3") ",")
;;;"1,2,3"
(defun p-string-connect	(lst delim / e str)
  (setq	str (car lst)
	lst (cdr lst)
  )
  (while (setq e (car lst))
    (setq str (strcat str delim e))
    (setq lst (cdr lst))
  )
  str
)
;; (p-string-left "123" 1)
;; "1"
(defun p-string-left (str n)
  (substr str 1 n)
)
;; (p-string-right "123" 1)
;; "3"
;; (p-string-right "123" 100)
;; "123"
(defun p-string-right (str n / s sl)
  (setq	sl (strlen str)
	s  (- sl n -1)
  )
  (if (< s 1)
    (setq s 1)
  )
  (substr str s n)
)
;;;_$ (p-number-padding 2 3)
;;;"002"
(defun p-number-padding	(number len / r)
  (setq r (itoa number))
  (repeat (- len (strlen r))
    (setq r (strcat "0" r))
  )
  r
)
;; (p-number-padding-last pi 3)
(defun p-number-padding-last (number len / p r)
  (setq r (rtos number 2 len))
  (if (/= len 0)
    (progn
      (setq p (vl-string-search "." r))
      (if (null p)
        (setq p (strlen r)
              r (strcat r ".")
        )
      )
      (repeat (- len (strlen r) (- p) -1)
        (setq r (strcat r "0"))
      )
    )
  )
  r
)
;;; (p-set-values '((a . 10) (b . 20)))
(defun p-set-values (lst / old)
  (foreach e lst
    (setq old (cons (cons (car e) (vl-symbol-value (car e))) old))
    (set (car e) (cdr e))
  )
  (reverse old)
)


;;;(defun p-string-tokenize (str delim / buff l2)
;;;  (setq	str   (vl-string->list str)
;;;	delim (ascii delim)
;;;  )
;;;  (while str
;;;    (if	(= (car str) delim)
;;;;;;      (if buff
;;;      (setq l2	 (cons (vl-list->string (reverse buff)) l2)
;;;	    buff nil
;;;      )
;;;;;;      )
;;;      (setq buff (cons (car str) buff))
;;;    )
;;;    (setq str (cdr str))
;;;  )
;;;;;;  (if buff
;;;  (setq l2 (cons (vl-list->string (reverse buff)) l2))
;;;;;;  )
;;;  (reverse l2)
;;;)
;;;_$ (p-string-tokenize "AA,1500,800,15 0" ", ")
;;;("AA" "1500" "800" "15" "0")
(defun p-string-tokenize (str delim / buff l2)
  (setq	str   (vl-string->list str)
	delim (vl-string->list delim)
  )
  (while str
    (if	(member (car str) delim)
      (setq l2	 (cons (vl-list->string (reverse buff)) l2)
	    buff nil
      )
      (setq buff (cons (car str) buff))
    )
    (setq str (cdr str))
  )
  (setq l2 (cons (vl-list->string (reverse buff)) l2))
  (reverse l2)
)

;;
(defun p-string-setnotempty (symbol value /)
  (if (or (null (vl-symbol-value symbol))
	  (equal (vl-symbol-value symbol) "")
      )
    (set symbol value)
  )
)
;;;(defun p-string-buffappend (sb str)
;;;  (set sb (append (reverse (vl-string->list str)) (vl-symbol-value sb)))
;;;)
;;;
;;;(defun p-string-buff->string (sb)
;;;  (vl-list->string (reverse (vl-symbol-value sb)))
;;;)
;;;(defun test ()
;;;  (setq a "")
;;;;;;  (repeat (setq n 10000)
;;;;;;    (p-string-buffappend 'a (itoa (setq n (1- n))))
;;;;;;  )
;;;;;;  (p-string-buff->string 'a)
;;;  (repeat (setq n 10000)
;;;    (setq a (strcat a (itoa (setq n (1- n)))))
;;;  )
;;;  (princ)
;;;)


;;; (p-template-parse-inner "A(A)B(12)" "(" ")")
;;; ("A" ("A") "B" ("12"))
(defun p-template-parse-inner (template gs ge / buff ch result)
  (setq template (vl-string->list template))

  (while (setq ch (car template))
    (cond
      ((= ch (ascii gs)) ;_ {
       (if buff
	 (setq result (cons (vl-list->string (reverse buff)) result) ;_ { ��ͨ�ı��Ľ���
	       buff   nil
	 )
       )
      )
      ((= ch (ascii ge)) ;_ }
       (if buff
	 (setq result
		(cons (list (vl-list->string (reverse buff))) result) ;_ } ���Խ���
	       buff nil
	 )
       )
      )
      (t
       (setq buff (cons ch buff))
      )
    )
    (setq template (cdr template))
  )
  (if buff
    (setq result (cons (vl-list->string (reverse buff)) result))
  )
;;;  (reverse result)
  (mapcar (function (lambda (e)
                      (if (atom e)
                        e
                        (p-string-tokenize (car e) ":")
                      )
                    )
          )
          (reverse result)
  )
)


;;;_$ (p-template-parse "{SERVICE}{NUMBER}-{DN}-{SPECNAME}-{INSULATION}")
;;;(("SERV") ("NUMBER") "-" ("DN") "-" ("SPECNAME") "-" ("INSULATION"))
(defun p-template-parse	(template /)
  (p-template-parse-inner template "{" "}")
)


;;;_$ (p-template-eval "DN{DN:2}" '(("DN" . 3.1)))
;;;"DN3.10"
(defun p-template-eval (template params / r)
  (apply
    'strcat
    (mapcar
      (function	(lambda	(e)
		  (if (vl-consp e)
		    (if	(setq r (p-get params (car e)))
		      (cond ((numberp r)
                             (setq dig (cadr e))
                             (if (null dig)
                               (setq dig 0)
                               (setq dig (atoi dig))
                             )
                             (p-number-padding-last r dig);_ ģ��"{L:2}"����������L(������λС��)
			    )
			    (t
			     (vl-princ-to-string r)
			    )
		      )
		      (strcat "{" (car e) "}") ;_ ���Բ�����ʱ�޸�Ϊ����ģ�屾��
		    )
		    e
		  )
		)
      )
      (p-template-parse template)
    )
  )
  ;; �޸�Ϊ��ָ�����Բ�����ʱ����nil
;;;  (setq	tmpl (p-template-parse template)
;;;	str  ""
;;;  )
;;;  (while tmpl
;;;    (if	(vl-consp (car tmpl))
;;;      (if (setq r (cdr (assoc (caar tmpl) params)))
;;;	(setq str (strcat str (vl-princ-to-string r)))
;;;	(setq str  nil
;;;	      tmpl nil
;;;	)
;;;      )
;;;      (setq str (strcat str (car tmpl)))
;;;    )
;;;    (setq tmpl (cdr tmpl))
;;;  )
;;;  str
)





;;; ��ȡ������
;;;_$ (p-get '((10 . "1") (11 . "2")) 11)
;;;"2"
;;;_$ (p-get '((10 . "1") (11 . "2")) '(11 10))
;;;("2" "1")
;;;_$ (p-get '((10 . "1") (11 . "2")) 12)
;;;nil
;;;_$ (p-get '((10 . "1") (11 . "2")) nil)
;;;nil
(defun p-get (lst keys /)
  (if (atom keys)
    (cdr (assoc keys lst))
    (mapcar (function (lambda (e) (cdr (assoc e lst)))) keys)
  )
)
;;;_$ (p-get1 '((10 . "1") (11 . "2")) 11)
;;;(11 . "2")
;;;_$ (p-get1 '((10 . "1") (11 . "2")) '(11 12))
;;;((11 . "2") (12))
;;;_$ (p-get1 '((10 . "1") (11 . "2")) 12)
;;;(12)
;;;_$ (p-get1 '((10 . "1") (11 . "2")) nil)
;;;(nil)
(defun p-get1 (lst keys / e)
  (if (atom keys)
    (cons keys (p-get lst keys))
    (mapcar 'cons keys (p-get lst keys))
  )
)
;;; ����������
;;;_$ (p-set '() '("A" . 10))
;;;(("A" . 10))
;;;_$ (p-set nil '("A" . 10))
;;;(("A" . 10))
;;;_$ (p-set nil '(("A" . 10)("B" . "string..")))
;;;(("A" . 10) ("B" . "string.."))
;;;_$ (setq ob '(("A" 12)("B" . 1)))
;;;(("A" 12) ("B" . 1))
;;;_$ (p-set ob '(("A" 10)("B" . "asdf")))
;;;(("A" 10) ("B" . "asdf"))
;;;_$ (p-set '((1 . "2")) '((1 . "1") (2 . "2")))
;;;((1 . "1") (2 . "2"))
(defun p-set (lst values / old)
  ;; ǿ��'(1 . 1) ת���� '((1 . 1)) ʹ��������ͳһ
  (if (and values (atom (car values)))
    (setq values (list values))
  )
  (foreach value values
    (if	(setq old (assoc (car value) lst))
      (setq lst (subst value old lst))
      (setq lst (append lst (list value)))
    )
  )
  lst
)
;;;_$ (p-set1 '((1 . "2")) 1 12)
;;;((1 . 12))
;;;_$ (p-set1 '((1 . "2")) 2 12)
;;;((1 . "2") (2 . 12))
(defun p-set1 (lst key value / old)
  (if (setq old (assoc key lst))
    (setq lst (subst (cons key value) old lst))
    (setq lst (append lst (list (cons key value))))
  )
)
;; (p-unset '(("A" . 10)("B" . "string..")) "A")
;; (("B" . "string.."))
;;;_$ (p-unset '(("A" . 10)("B" . "string..")) '("A" "B"))
;;;nil
(defun p-unset (lst keys /)
  (if (atom keys)
    (setq keys (list keys))
  )
  (vl-remove-if
    (function (lambda (e) (member (car e) keys)))
    lst
  )
)
;;; �������������б�ֵ��������
;;;(defun p-cls-append (lst values /)
;;;  (p-set lst (append (assoc (car values) lst) (cdr values)))
;;;)
;;;_$ (p-cls-append ob '("A" 20))
;;;(("A" 12 20) ("B" . 1))



;;;_$ (p-dxf (car (entsel)) 0)
;;;"LINE"
;;;_$ (p-dxf (car (entsel)) '(0 5 10 11))
;;;("LINE" "1D3" (860.434 761.443 0.0) (1063.61 1512.12 0.0))
(defun p-dxf (ename keys /)
  (p-get (entget ename) keys)
)
;;; (p-dxf1 (car (entsel)) '(10 11))
;;; ((10 1019.75 1312.56 0.0) (11 2080.69 1885.93 0.0))
(defun p-dxf1 (ename keys /)
  (p-get1 (entget ename) keys)
)
;;; (p-dxfs (car (entsel)) '(p0 p1) '(10 11))
(defun p-dxfs (ename sym keys /)
  (mapcar (function set) sym (p-dxf ename keys))
)
;;;(p-var-set '(a b c) '(1 2 3))
;;;_$ a
;;;1
;;;_$ b
;;;2
;;;_$ c
;;;3
;;;(p-var-set '(p0 p1) (p-dxf (car (entsel)) '(10 11)))
;;;(defun p-var-set (symbols values /)
;;;  (mapcar 'set symbols values)
;;;)


;;;(p-entsel-inner "\nSelect a object or [(Sop)]:" "*" nil)
(defun p-entsel-inner (msg filter nested / ent kword)
  (if (and msg
	   (setq kword (mapcar 'car
			       (vl-remove-if-not
				 'vl-consp
				 (p-template-parse-inner msg "(" ")")
			       )
		       )
	   )
      )
    (setq kword	(p-string-connect kword " ")
	  kword	(strcat kword "  ")
    )
    (setq kword "  ")
  )

  (while (null ent)
    (initget kword)

    (if	nested
      (setq ent (nentsel msg))
      (setq ent (entsel msg))
    )

    (cond
      ((null ent)
       (princ "δѡ�����")
      )

      ((= (type ent) 'list)
       (if (and	filter
		(not (wcmatch (p-dxf (car ent) 0) filter))
	   )
	 (progn
	   (princ "ѡ������ѱ����ˡ�")
	   (setq ent nil)
	 )
       )
      )
    )
  )
  ent
)


(defun p-entsel	(msg filter /)
  (p-entsel-inner msg filter nil)
)


(defun p-nentsel (msg filter /)
  (p-entsel-inner msg filter t)
)

(defun p-enamep (v)
  (= 'ename (type v))
)

(defun p-enames-after (en ss /)
  (if (null ss)
    (setq ss (ssadd))
  )
  (while (setq en (entnext en))
    (setq ss (ssadd en ss))
  )
  ss
)

(defun p-enames->ss (enames / ss)
  (setq ss (ssadd))
  (foreach en enames
    (ssadd en ss)
  )
  ss
)


;;; (p-ss->enames (ssget))
(defun p-ss->enames (ss / en handles n)
  (if ss
    (progn
      (repeat (setq n (sslength ss))
	(setq en      (ssname ss (setq n (1- n)))
	      handles (cons en handles)
	)
      )
    )
  )
  handles
)
;;; (p-ss->handles (ssget))
(defun p-ss->handles (ss / e)
  (mapcar (function (lambda (e) (p-dxf e 5)))
	  (p-ss->enames ss)
  )
)

(defun p-ss-highlight-inner (ss status / en n)
  (if ss
    (progn
      (repeat (setq n (sslength ss))
	(setq en (ssname ss (setq n (1- n))))
	(redraw en status)		; 4 unhighlight
      )
    )
  )
)

(defun p-ss-highlight (ss / en n)
  (if $p-ss-highlighted
    (progn
      (p-ss-highlight-inner $p-ss-highlighted 4)
      (setq $p-ss-highlighted nil)
    )
  )

  (if ss
    (progn
      (p-ss-highlight-inner ss 3)
      (setq $p-ss-highlighted ss)
    )
  )
)

;;;_$ (p-line-getendnear (car (entsel)) (getpoint))
;;;(11 2080.69 1885.93 0.0)
;;; p WCS��
(defun p-line-getendnear (line p / pts)
  (setq pts (p-dxf1 line '(10 11)))

  (if (< (distance (cdar pts) p) (distance (cdadr pts) p))
    (car pts)
    (cadr pts)
  )
)

;;; (p-line-getangle (car (entsel)))
;;; 0.49547
(defun p-line-getangle (line /)
  (apply 'angle (p-dxf (p-ensure-ename line) '(10 11)))
)

(defun p-line-getinters	(l1 l2 / dx1 dx2)
  (setq	dx1 (entget l1)
	dx2 (entget l2)
  )
  (inters (cdr (assoc 10 dx1))
	  (cdr (assoc 11 dx1))
	  (cdr (assoc 10 dx2))
	  (cdr (assoc 11 dx2))
	  nil ;_ ��������ֱ����
  )
)


(defun p-line-closestpoint (line p extend)
  (vlax-curve-getclosestpointto
    (p-ensure-object line)
    p
    extend
  )
)

(defun p-line-parallel (l1 l2 / a)
  (setq a (p-angle-include (p-line-getangle l1) (p-line-getangle l2)))
  (or (equal a pi 1e-2) (equal a 0. 1e-2))
)
;;

(defun p-clipboard-set (str / html result)
  (and (= (type str) 'str)
       (setq html (vlax-create-object "htmlfile"))
       (setq result (vlax-invoke
		      (vlax-get	(vlax-get html 'parentwindow)
				'clipboarddata
		      )
		      'setdata
		      "Text"
		      str
		    )
       )
       (vlax-release-object html)
  )
)

(defun p-clipboard-get (/ html result)
  (and (setq html (vlax-create-object "htmlfile"))
       (setq result (vlax-invoke
		      (vlax-get	(vlax-get html 'parentwindow)
				'clipboarddata
		      )
		      'getdata
		      "Text"
		    )
       )
       (vlax-release-object html)
  )
  result
)

;; ��Ŀ¼����Ŀ¼�в����ļ�
;; (p-file-search (psk-get-filename "\\catelog") "*.csv")
;; ("D:\\Profile\\desktop\\dd3\\bin\\catelog\\fcu\\fp.csv" "D:\\Profile\\desktop\\dd3\\bin\\catelog\\vrf\\daikin\\�������յ����ڻ������.csv")
(defun p-file-search (path patten / r)
  (foreach dir (cddr (vl-directory-files path nil -1))
    (setq r (append r (p-file-search (strcat path "\\" dir) patten)))
  )
  (foreach file	(vl-directory-files path patten 0)
    (setq r (cons (strcat path "\\" file) r))
  )
  r
)


;; 
(defun p-directory-make	(folder / folders cur)
  (setq	folder	(vl-string-trim "\\/" folder)
	folders	(p-string-tokenize folder "\\/")
	cur	(car folders)
	folders	(cdr folders)
  )
  (foreach e folders
    (setq cur (strcat cur "\\" e))
    (if	(null (vl-file-directory-p cur))
      (vl-mkdir cur)
    )
  )
)

(defun p-file-read (filename / content file line)
  (if (and (setq filename (findfile filename))
           (setq file (open filename "r"))
      )
    (progn
      (while (setq line (read-line file))
        (setq content (cons line content))
      )
      (close file)
    )
  )
  (reverse content)
)
(defun p-file-readstring (filename / content)
  (if (setq content (p-file-read filename))
    (p-string-connect content "\r\n")
  )
)
;; (p-file->string "a.txt")
;; "text..."
;;;(defun p-file->string (filename / content file line)
;;;  (if (and (setq file (findfile filename))
;;;	   (setq file (open file "r"))
;;;      )
;;;    (progn
;;;      (while (setq line (read-line file))
;;;        (setq line    (strcat line "\r\n")
;;;              content (cons line content)
;;;        )
;;;      )
;;;      (setq content (apply (function strcat) (reverse content)))
;;;
;;;      (close file)
;;;    )
;;;  )
;;;  content
;;;)

(defun p-lisp-load (filename /)
  (if (setq content (p-file-readstring filename))
    (read content)
    (princ (strcat "\npsk-load-lispfile����: �޷������ļ� \""
		   filename
		   "\""
	   )
    )
  )
)


;;; �������ñ�ת��һ����������
;;;(defun p-convert-datatype (v dt /)
;;;  (cond
;;;    ((= dt 1040)
;;;     (atof v)
;;;    )
;;;    ((= dt 1070)
;;;     (atoi v)
;;;    )
;;;    (t
;;;     v
;;;    )
;;;  )
;;;)
;;; (p-convert-rowdatatype '("A" "1" "2") '((1 . 1040) (2 . 1070)))
;;; ("A" 1.0 2)
;;;(defun p-convert-rowdatatype (row dtable / dt n rv v)
;;;  (setq n 0)
;;;  (while row
;;;    (setq dt  (cdr (assoc n dtable))
;;;	  v   (p-convert-datatype (car row) dt)
;;;	  rv  (cons v rv)
;;;	  row (cdr row)
;;;	  n   (1+ n)
;;;    )
;;;  )
;;;  (reverse rv)
;;;)



;;;(defun p-csvfile-read-inner (filename dtable / e file line table)
;;;  (if (setq file (open filename "r"))
;;;    (progn
;;;      (while (setq line (read-line file))
;;;	(setq line (vl-string-trim " \t\n," line))
;;;
;;;	(if (and (/= line "")
;;;		 (setq line (p-string-tokenize line ","))
;;;	    )
;;;	  (setq	line  (mapcar '(lambda (e) (vl-string-subst "\"" "\"\"\"" e))
;;;			      line
;;;		      )
;;;		line  (p-convert-rowdatatype line dtable)
;;;		table (cons line table)
;;;	  )
;;;	)
;;;      )
;;;      (close file)
;;;    )
;;;    (princ
;;;      (strcat "\nError (p-csvfile-read): CAN'T OPEN FILE \""
;;;	      filename
;;;	      "\""
;;;      )
;;;    )
;;;  )
;;;  (reverse table)
;;;)


;; (p-csvfile-read (psk-get-filename "\\sizes\\flange pn.csv"))
(defun p-csvfile-read (filename / r rows)
  (if (setq rows (p-file-read filename))
    (progn
      (foreach row rows
        (setq row (vl-string-trim " \t\n," row))
        (if (and (/= row "")
                 (/= (p-string-left row 2) "//")
                 (setq row (p-string-tokenize row ","))
            )
          (setq row (mapcar (function (lambda (e) (vl-string-subst "\"" "\"\"\"" e)))
                            row
                    )
                r   (cons row r)
          )
        )
      )
      (reverse r)
    )
  )
)
;;

;;; �������csv���ݼ��ط����������Ѽ��ع����ļ�ֱ�Ӵӻ������з��ؽ������csv���ݱ���������ݷ����ٶ�
;;; (p-csvfile-readcache (psk-get-filename "sizes/flange pn.csv") '$psk-csvread-cache)
(defun p-csvfile-readcache (filename cache / data)
  (if (and (setq filename (findfile filename))
           (setq filename (strcase filename))
           (null (setq data (p-get (vl-symbol-value cache) filename))) ;_ ���ļ�����дΪ��������
      )
    (progn
      (setq data (p-csvfile-read filename))
      (set cache (cons (cons filename data) (vl-symbol-value cache)))
    )
  )
  data
)
;; (p-csvread-keys (p-csvfile-read "\\catelog\\vrf\\daikin\\�������յ����ڻ������.csv"))
;; ("F2.8" "F3.6" "F4.5" "F5.6" "F7.1" "F8" "F9" "F10" "F11.2" "F12.5" "F14" "D2.2" "D2.5" "D2.8" "D3.2" "D3.6" "D4" "D4.5" "D5" "D5.6" "D6.3" "D7.1" "S2.2" "S2.8" "S3.6" "S4.5" "S5.6" "S7.1" "S8" "S9" "S10" "S11.2" "S12.5" "S14" "S15" "Q10" "Q16" "Q20" "Q25" "Q30" "Q40")
(defun p-csvread-keys (csv /)
  (mapcar (function car) (cdr csv))
)
;;;_$ (p-csvread-get rows "F2.8")
;;;(("NAME" . "F2.8") ("DESC" . "����������ڻ�") ("CLD" . "2.8") ("HLD" . "3.2") ("POW" . "0.053") ("NOIS" . "30") ("CMH" . "") ("ESP" . "") ("PS" . "220V") ("DWG" . "FXFP-KMVC") ("PORT" . "") ("PORT2" . "DN32"))
(defun p-csvread-get (csv key /)
  (mapcar (function cons) (car csv) (p-get1 (cdr csv) key))
)
;; ��������������������ת�� ����#��ͷ��������ֵת��Ϊ���ַ��ص����������#�ַ�
;;;_$ (p-csvread-get1 csv "FL-PL-2.5-15")
;;;(("Name" . "FL-PL-2.5-15") ("OD" . 80.0) ("BLTD" . 55.0) ("BLTH" . 11.0) ("BLTN" . "M10") ("BLTA" . 4.0) ("L" . 12.0))
(defun p-csvread-get1 (csv key / r)
  (setq r (p-csvread-get csv key))
  (mapcar (function (lambda (e)
                      (if (= "#" (p-string-left (car e) 1))
                        (cons (vl-string-trim "#" (car e)) (atof (cdr e)))
                        e
                      )
                    )
          )
          r
  )
)


;;;_$ (p-csvfile-get3 "D:/Profile/desktop/dd3/bin/config/sizes/flange pn.csv" "FL-PL-2.5-15" '("FlangeDiameter" "Length"))
;;;(("FlangeDiameter" . 80) ("Length" . 12))
;;;(p-csvfile-getprop "/size/flange pn.csv" "FL-PL-2.5-15" nil)
;;;((NAME . "FL-PL-2.5-15") (FLANGEDIAMETER . 80) (BOLTARRANGEDIAMETER . 55) (BOLTHOLEDIAMETER . 11) (BOLTCODE . M10) (NUMBEROFBOLTHOLES . 4) (LENGTH . 12))
;;;(defun p-csvfile-get3 (filename key symbols / data e pos)
;;;  (setq data (p-csvfile-read filename))
;;;  (if data
;;;    (progn
;;;      (if (null symbols)
;;;	(setq symbols (car data)) ;_ symbolsΪnilʱ������������
;;;      )
;;;      (setq pos	 (mapcar '(lambda (e) (vl-position e (car data)))
;;;			 (mapcar 'read symbols)
;;;		 ) ;_ ���ݱ�ͷ��ȡ�ֶ�˳��
;;;	    data (assoc key data)
;;;      )
;;;      (mapcar 'cons
;;;	      symbols
;;;	      (mapcar '(lambda (e) (nth e data)) pos)
;;;      )
;;;    )
;;;  )
;;;)


;;;(defun p-get-csvfile-keylist (filename / data)
;;;  (setq data (p-csvfile-readcache (p-get-filename filename)))
;;;  (mapcar 'car (cdr data))
;;;)











;;;(defun p-rtos	(num / count remain ret)
;;;
;;;  (setq	ret    (itoa (fix num))
;;;	remain (- num (fix num))
;;;	count  0
;;;  )
;;;
;;;  (if (not (equal 0. remain 1e-6))
;;;    (setq ret (strcat ret "."))
;;;  )
;;;
;;;  (while (and (< count 100)
;;;	      (not (equal 0. remain 1e-10))
;;;	 )
;;;    (setq remain (* 10 remain)
;;;	  ret	 (strcat ret (itoa (fix remain)))
;;;	  remain (- remain (fix remain))
;;;	  count	 (1+ count)
;;;    )
;;;  )
;;;
;;;  ret
;;;)

;;;(defun p-config-restore (filename / f line text data)
;;;  (setq	f    (open filename "r")
;;;	text ""
;;;  )
;;;  (while (setq line (read-line f))
;;;    (setq text (strcat text line))
;;;  )
;;;  (close f)
;;;
;;;  (setq data (read text))
;;;  (mapcar '(lambda (x) (set (car x) (cdr x))) data)
;;;)
;;;
;;;
;;;(defun p-config-save (filename symbols / f data)
;;;  (setq
;;;    data
;;;     (apply
;;;       'list
;;;       (mapcar
;;;	 '(lambda (x) (cons x (vl-symbol-value x)))
;;;	 symbols
;;;       )
;;;     )
;;;  )
;;;  (setq f (open filename "w"))
;;;  (prin1 data f)
;;;  (close f)
;;;)




;; (p-regexp-match "K1-1 10" "K\\d+(\\.\\d+)-")
;;;_$ (p-regexp-match "K01-21 100" "\\d+")
;;;("01" "21" "100")
(defun p-regexp-match (str pattern / matchs reg r)
  (setq reg (vlax-create-object "vbscript.regexp"))
  (vlax-put-property reg 'global 1)
  (vlax-put-property reg 'ignorecase 1)
  (vlax-put-property reg 'pattern pattern)

  (setq matchs (vlax-invoke reg 'execute str))
  (vlax-for k matchs
    (setq r (cons (vlax-get k 'value) r))
  )
  (vlax-release-object reg)
  (reverse r)
)


;;;_$ (p-regexp-replace "K1-2 44" "(K.-)(\\d+)([^s]*)" "$13$3")
;;;"K1-3 44"

;;;_$ (p-regexp-replace "http://www.wrox.com:80/misc-pages/support.shtml" "(\\w+):\\/\\/([^/:]+)(:\\d*)?([^#]*)" "")
;;;""
;;;_$ (p-regexp-replace "http://www.wrox.com:80/misc-pages/support.shtml" "(\\w+):\\/\\/([^/:]+)(:\\d*)?([^#]*)" "$1")
;;;"http"
;;;_$ (p-regexp-replace "http://www.wrox.com:80/misc-pages/support.shtml" "(\\w+):\\/\\/([^/:]+)(:\\d*)?([^#]*)" "$2")
;;;"www.wrox.com"
;;;_$ (p-regexp-replace "http://www.wrox.com:80/misc-pages/support.shtml" "(\\w+):\\/\\/([^/:]+)(:\\d*)?([^#]*)" "$3")
;;;":80"
;;;_$ (p-regexp-replace "http://www.wrox.com:80/misc-pages/support.shtml" "(\\w+):\\/\\/([^/:]+)(:\\d*)?([^#]*)" "$4")
;;;"/misc-pages/support.shtml"

;;;_$ (p-regexp-replace "<title>A Title</title><!-- a title tag -->" "(^.*)(<!--.*-->)(.*$)" "$1")
;;;"<title>A Title</title>"
;;;_$ (p-regexp-replace "<title>A Title</title><!-- a title tag -->" "(^.*)(<!--.*-->)(.*$)" "$3")
;;;""
;;;_$ (p-regexp-replace "<title>A Title</title><!-- a title tag -->" "(^.*)(<!--.*-->)(.*$)" "$2")
;;;"<!-- a title tag -->"
(defun p-regexp-replace	(str pattern new / reg r)
  (setq reg (vlax-create-object "vbscript.regexp"))
  (vlax-put-property reg 'pattern pattern)
  (vlax-put-property reg 'global 1)
  (vlax-put-property reg 'ignorecase 1)
  (setq r (vlax-invoke reg 'replace str new))
  (vlax-release-object reg)
  r
)

(defun p-jscript-eval (func_str /)
  (if (null $p-scriptcontrol)
    (progn
      (setq $p-scriptcontrol
	     (vlax-create-object
	       "Aec32BitAppServer.AecScriptControl.1"
	     )
      )
      (vl-catch-all-apply
	'vlax-put
	(list $p-scriptcontrol "language" "jscript")
      )
    )
  )
  (if (null $p-scriptcontrol)
    nil
    (vl-catch-all-apply
      'vlax-invoke
      (list
	$p-scriptcontrol
	"eval"
	func_str
      )
    )
  )
)


(defun p-timestamp ()
  (getvar "MILLISECS")
)


;;; BENCHMARK

(defun p-timer-start ()
  (setq $p-timestart (p-timestamp))
)


(defun p-timer-stop (/ el)
  (setq el (- (p-timestamp) $p-timestart))
  (setq $p-timestart (p-timestamp))
  el
)

(defun p-benchmark (expr n / elapse tps start)
  (setq start (getvar "MILLISECS"))

  (repeat n
    (eval expr)
  )

  (setq elapse (- (getvar "MILLISECS") start))

  (if (equal elapse 0. 1e-6)
    (strcat "Benchmark loops = "
	    (itoa n)
	    ", in "
	    (rtos elapse 2 4)
	    " ms"
    )
    (strcat "Benchmark loops = "
	    (itoa n)
	    ", in "
	    (rtos elapse 2 4)
	    " ms, "
	    (rtos (/ n elapse 1e-3) 2 0)
	    " invoke / s"
    )
  )
)



(princ)
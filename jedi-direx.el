;;; jedi-direx.el --- Tree style viewer for Python buffers

;; Copyright (C) 2013 Takafumi Arakaki

;; Author: Takafumi Arakaki <aka.tkf at gmail.com>

;; This file is NOT part of GNU Emacs.

;; jedi-direx.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; jedi-direx.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with jedi-direx.el.
;; If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(require 'jedi)
(require 'direx)


(defclass jedi-direx:object (direx:tree)
  ((cache :initarg :cache :document "Subtree of `jedi:defined-names--cache'")))
(defclass jedi-direx:module (jedi-direx:object direx:node)
  ((file-name :initarg :file-name
              :accessor direx:file-full-name)))
(defclass jedi-direx:class (jedi-direx:object direx:node) ())
(defclass jedi-direx:method (jedi-direx:object direx:leaf) ())
(defclass jedi-direx:variable (jedi-direx:object direx:leaf) ())

(defvar jedi-direx:type-class-map
  '(("class" . jedi-direx:class)
    ("function" . jedi-direx:method)))

(defun jedi-direx:node-from-cache (cache)
  (let* ((type (plist-get (car cache) :type))
         (class (or (assoc-default type jedi-direx:type-class-map)
                    'jedi-direx:variable)))
    (make-instance class
                   :cache cache
                   :name (plist-get (car cache) :name))))

(defmethod direx:node-children ((node jedi-direx:object))
  (mapcar 'jedi-direx:node-from-cache (cdr (oref node :cache))))

(defmethod direx:tree-equals ((x jedi-direx:object) y)
  (and (typep y 'jedi-direx:object)
       (equal (direx:tree-name x)
              (direx:tree-name y))))


;;; View

(defclass jedi-direx:item (direx:item) ())

(defmethod direx:make-item ((tree jedi-direx:object) parent)
  (make-instance 'jedi-direx:item :tree tree :parent parent))

(defun direx-jedi:-goto-item (item)
  (destructuring-bind (&key line_nr column &allow-other-keys)
      (car (oref (direx:item-tree item) :cache))
    (jedi:goto--line-column line_nr column)))

(defmethod direx:generic-find-item ((item jedi-direx:item)
                                    not-this-window)
  (let* ((root (direx:item-root item))
         (filename (direx:file-full-name (direx:item-tree root))))
    (if not-this-window
        (find-file-other-window filename)
      (find-file filename))
    (direx-jedi:-goto-item item)))

(defmethod direx:generic-display-item ((item jedi-direx:item))
  (let* ((root (direx:item-root item))
         (filename (direx:file-full-name (direx:item-tree root))))
    (with-selected-window (display-buffer (find-file-noselect filename))
      (direx-jedi:-goto-item item))))


;;; Command

(defun jedi-direx:make-buffer ()
  (direx:ensure-buffer-for-root
   (make-instance 'jedi-direx:module
                  :name (format "*direx-jedi: %s*" (buffer-name))
                  :file-name (buffer-file-name)
                  :cache jedi:defined-names--cache)))

(defun jedi-direx:pop-to-buffer ()
  (interactive)
  (pop-to-buffer (jedi-direx:make-buffer)))

(defun jedi-direx:switch-to-buffer ()
  (interactive)
  (switch-to-buffer (jedi-direx:make-buffer)))


(provide 'jedi-direx)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; jedi-direx.el ends here

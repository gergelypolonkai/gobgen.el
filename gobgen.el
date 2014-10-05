;;; gobgen.el --- Generate GObject descendants using a detailed form
;; Author: Gergely Polonkai <gergely@polonkai.eu>
;; Copyright: GPL
;; URL: https://github.com/gergelypolonkai/gobgen.el
;; Keywords: gobject, glib, gtk, helper, utilities
;;; Commentary:
;; Generator code is highly based on Gustavo Sverzut Barbieri's
;; gobject-class.el
;;; Code:


(require 'widget)

(eval-when-compile (require 'wid-edit))

(defvar gobgen-widget-name)
(defvar gobgen-widget-prefix)
(defvar gobgen-widget-parent-name)
(defvar gobgen-widget-parent-prefix)
(defvar gobgen-widget-recent)
(defvar gobgen-widget-private)

(defun string-join (list separator)
  "Takes a list of string and joins them using delimiter."
  (mapconcat (lambda (x) x) list separator))

(defun string-has-prefix (full-str prefix-str)
  "Check if full-str has the prefix prefix-str"

  (let* ((prefix-length (length prefix-str)))
    (string-equal prefix-str (substring full-str 0 prefix-length))))

(defun get-gobject-prefix (class-name)
  (car (split-string class-name "_")))

(defun gobgen-gen-header ()

  (concat
   "#ifndef __"
   CLASS_FULL_NAME
   "_H__\n"

   "#define __"
  CLASS_FULL_NAME
  "_H__\n"

  "\n"

  (if (string-equal "g" parent_prefix)
      "#include <glib-object.h>"
    (if (string-equal "gtk" parent_prefix)
        "#include <gtk/gtk.h>"
      (concat "// You might want to revise this\n"
              "#include <"
              parent-header
              ">")))
  "\n"

  "\n"

  "G_BEGIN_DECLS\n"

  "\n"

  "#define " CLASS_PREFIX "_TYPE_" CLASS_NAME "         (" func-prefix "_get_type())\n"

  "#define " CLASS_FULL_NAME "(o)           (G_TYPE_CHECK_INSTANCE_CAST((o), " CLASS_PREFIX "_TYPE_" CLASS_NAME ", " ClassFullName "))\n"

  "#define " CLASS_FULL_NAME "_CLASS(k)     (G_TYPE_CHECK_CLASS_CAST((k), " CLASS_PREFIX "_TYPE_" CLASS_NAME ", " ClassFullName "Class))\n"

  "#define " CLASS_PREFIX "_IS_" CLASS_NAME "(o)        (G_TYPE_CHECK_INSTANCE_TYPE((o), " CLASS_PREFIX "_TYPE_" CLASS_NAME "))\n"

  "#define " CLASS_PREFIX "_IS_" CLASS_NAME "_CLASS(k)  (G_TYPE_CHECK_CLASS_TYPE((k), " CLASS_PREFIX "_TYPE_" CLASS_NAME "))\n"

  "#define " CLASS_FULL_NAME"_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS((o), " CLASS_PREFIX "_TYPE_" CLASS_NAME ", " ClassFullName "Class))\n"

  "\n"

  "typedef struct _" ClassFullName "      " ClassFullName ";\n"

  "typedef struct _" ClassFullName "Class " ClassFullName "Class;\n"

  (if (and (not recent-glib) need-private)
      (concat "typedef struct _" ClassFullName "Private " ClassFullName "Private;\n"))

  "\n"

  "struct _" ClassFullName " {\n"

  "    /* Parent instance structure */\n"

  "    " ParentPrefix ParentName " parent_instance;\n"

  "\n"

  "    /* Instance members */\n"

  (if (and (not recent-glib) need-private)
      (concat "\n"
	      "    /*< private >*/\n"
	      "    " ClassFullName "Private *priv;\n"))

  "};\n"

  "\n"

  "struct _" ClassFullName "Class {\n"

  "    " ParentPrefix ParentName "Class parent_class;\n"

  "};\n"

  "\n"

  "GType " func-prefix "_get_type(void) G_GNUC_CONST;\n"

  "\n"

  "G_END_DECLS\n"

  "\n"

  "#endif /* __"
  CLASS_FULL_NAME
  "_H__ */\n"))

(defun gobgen-gen-code ()
  (concat
   "#include \"" file-name-header "\"\n"

   "\n"

   (if need-private
       (concat
	(if (not recent-glib)
	    (concat
	     "#define " CLASS_FULL_NAME "_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE( \\\n"
	     "            (o), \\\n"
	     "            " CLASS_PREFIX "_TYPE_" CLASS_NAME ", \\\n"
	     "            " ClassFullName "Private \\\n"
	     "        ))\n"
	     "\n"))

	(if recent-glib "typedef ")

	"struct _" ClassFullName "Private {\n"
	"    /* TODO: You must add something here, or GLib will produce warnings! */\n"
	"}"

	(if recent-glib
	    (concat " " ClassFullName "Private"))

	";\n"
	"\n"))

   "G_DEFINE_TYPE"

   (if (and recent-glib need-private)
       "_WITH_PRIVATE")

   "(" ClassFullName ", " func-prefix ", " PARENT_PREFIX "_TYPE_" PARENT_NAME ");\n"

   "\n"

   "static void\n"
   func-prefix "_finalize(GObject *gobject)\n"
   "{\n"
   "    g_signal_handlers_destroy(gobject);\n"
   "    G_OBJECT_CLASS(" func-prefix "_parent_class)->finalize(gobject);\n"
   "}\n"

   "\n"

   "static void\n"
   func-prefix "_class_init(" ClassFullName "Class *klass)\n"
   "{\n"
   "    GObjectClass *gobject_class = G_OBJECT_CLASS(klass);\n"
   "\n"

   (if (and (not recent-glib) need-private)
       (concat
	"    g_type_class_add_private(klass, sizeof(" ClassFullName "Private);\n"
	"\n"))

   "    gobject_class->finalize = " func-prefix "_finalize;\n"

   "}\n"

   "\n"

   "static void\n"
   func-prefix "_init(" ClassFullName " *" class_name ")\n"
   "{\n"

   (if (and (not recent-glib) need-private)
       (concat
	"    " class_name "->priv = " CLASS_FULL_NAME "_GET_PRIVATE(" class_name ");\n"))

   "}\n"))

(defun gobgen-generator ()
  "Generate the header definition for a GObject derived clas.

Parameters:
"
  (let* ((parent-prefix        (downcase parent-prefix))
         (parent-name          (downcase parent-name))
         (class-prefix         (downcase class-prefix))
         (class-name           (downcase class-name))
         (parent-prefix-length (length parent-prefix))
         (class-prefix-length  (length class-prefix)))

    (if (not (string-has-prefix parent-name (concat parent-prefix "_")))
        (message (concat "Parent (" parent-name ") and parent prefix (" parent-prefix ") don't match"))

      (if (not (string-has-prefix class-name (concat class-prefix "_")))
          (message (concat "Class (" class-name ") and class prefix (" class-prefix ") don't match"))

            (let* ((parent-name (substring parent-name (+ parent-prefix-length 1)))
                   (class-name  (substring class-name (+ class-prefix-length 1)))
                   (parent-prefix-pcs (split-string parent-prefix "_"))
                   (parent-name-pcs   (split-string parent-name "_"))
                   (class-prefix-pcs  (split-string class-prefix "_"))
                   (class-name-pcs    (split-string class-name "_"))
                   (parent_prefix     (string-join parent-prefix-pcs "_"))
                   (ParentPrefix      (mapconcat 'capitalize parent-prefix-pcs ""))
                   (PARENT_PREFIX     (upcase parent_prefix))
                   (parent_name       (string-join parent-name-pcs "_"))
                   (ParentName        (mapconcat 'capitalize parent-name-pcs ""))
                   (PARENT_NAME       (upcase parent_name))
                   (class_prefix      (string-join class-prefix-pcs "_"))
                   (ClassPrefix       (mapconcat 'capitalize class-prefix-pcs ""))
                   (CLASS_PREFIX      (upcase class_prefix))
                   (class_name        (string-join class-name-pcs "_"))
                   (ClassName         (mapconcat 'capitalize class-name-pcs ""))
                   (CLASS_NAME        (upcase class_name))
                   (func-prefix       (concat class_prefix "_" class_name))
		   (ClassFullName     (concat ClassPrefix ClassName))
		   (CLASS_FULL_NAME   (concat CLASS_PREFIX "_" CLASS_NAME))
		   (parent-header     (concat (string-join (append parent-prefix-pcs parent-name-pcs) "-") ".h"))
                   (file-name-base    (string-join (append class-prefix-pcs class-name-pcs) "-"))
		   (file-name-code    (concat file-name-base ".c"))
		   (file-name-header  (concat file-name-base ".h")))

              (delete-other-windows)
	      (split-window-vertically)
	      (other-window 1)
	      (find-file file-name-header)
	      (insert (gobgen-gen-header))

	      (split-window-vertically)
	      (other-window 1)
	      (find-file file-name-code)
	      (insert (gobgen-gen-code)))))))

(defun gobgen ()
  "Create widgets window for GObject creation"
  (interactive)
  (switch-to-buffer "*GObject Creator*")

  (kill-all-local-variables)

  (let ((inhibit-read-only t))
    (erase-buffer))

  (remove-overlays)

  (widget-insert "GObject Creator\n\n")

  (widget-insert "Generate a GObject class skeleton.\n\n")

  (setq gobgen-widget-name
        (widget-create 'editable-field
                       :size 25
                       :format "Name:   %v"
		       :notify (lambda (widget &rest ignore)
				 (save-excursion
				   (widget-value-set gobgen-widget-prefix (get-gobject-prefix (widget-value widget)))))
		       :doc "The name of the new class, with its prefix included"
                       "gtk_example_object"))

  (widget-insert " ")

  (setq gobgen-widget-prefix
        (widget-create 'editable-field
                       :size 10
                       :format "Prefix: %v\n"
		       :doc "Prefix of the new class. It updates automatically based on the name, so unless you need a namespace that consists of multiple parts (like my_ns), you should not touch this."
                       "gtk"))

  (setq gobgen-widget-parent-name
        (widget-create 'editable-field
                       :size 25
                       :format "Parent: %v"
		       :notify (lambda (widget &rest ignore)
				 (save-excursion
				   (widget-value-set gobgen-widget-parent-prefix (get-gobject-prefix (widget-value widget)))))
		       :doc "Name of the parent class. Use g_object if you don't want to derive from something specific."
                       "g_object"))

  (widget-insert " ")

  (setq gobgen-widget-parent-prefix
        (widget-create 'editable-field
                       :size 10
                       :format "Prefix: %v\n"
		       :doc "Prefix of the parent class. Its automatically set value should suffice most of the time"
                       "g"))

  (widget-insert "\n")

  (setq gobgen-widget-recent
        (widget-create 'checkbox
		       :doc "Use recent GLib's features, like defining a class with a private struct. Usually you would want this on."
                       t))

  (widget-insert " GLib >= 2.38\n")

  (setq gobgen-widget-private
        (widget-create 'checkbox
		       :doc "Add a private struct for the object."
                       nil))

  (widget-insert " Has private members\n")

  (widget-insert "\n\n")

  (widget-create 'push-button
                 :notify (lambda (&rest ignore)
                           (let ((class-name    (widget-value gobgen-widget-name))
                                 (class-prefix  (widget-value gobgen-widget-prefix))
                                 (parent-name   (widget-value gobgen-widget-parent-name))
                                 (parent-prefix (widget-value gobgen-widget-parent-prefix))
				 (recent-glib   (widget-value gobgen-widget-recent))
				 (need-private  (widget-value gobgen-widget-private)))
                             (gobgen-generator)))
                 "Generate")

  (widget-insert " ")

  (widget-create 'push-button
                 :notify (lambda (&rest ignore)
                           (gobgen-widgets))
                 "Reset form")

  (widget-insert " ")

  (widget-create 'push-button
                 :notify (lambda (&rest ignore)
                           (kill-buffer "*GObject Creator*"))
                 "Close")

  (beginning-of-buffer)

  (use-local-map widget-keymap)
  (widget-setup))

(provide 'gobgen)

;;; gobgen.el ends here

public class Layouts.ItemRow : Gtk.ListBoxRow {
    public Objects.Item item { get; construct; }

    private Gtk.CheckButton checked_button;
    private Widgets.HyperTextView content_textview;
    private Gtk.Label content_label;
    private Gtk.Revealer content_label_revealer;
    private Gtk.Revealer content_textview_revealer;
    private Gtk.Box content_top_box;
    private Gtk.Revealer detail_revealer;
    private Gtk.Revealer main_revealer;
    private Gtk.Grid handle_grid;
    private Gtk.Revealer top_motion_revealer;
    private Gtk.Revealer bottom_motion_revealer;
    private Gtk.EventBox itemrow_eventbox;
    private Widgets.LoadingButton submit_button;
    private Gtk.Button cancel_button;
    private Widgets.HyperTextView description_textview;
    private Gtk.Revealer actionbar_revealer;
    private Widgets.ProjectButton project_button;
    private Gtk.Revealer submit_cancel_revealer;
    private Widgets.ItemSummary item_summary;

    bool _edit = false;
    public bool edit {
        set {
            if (value) {
                handle_grid.get_style_context ().add_class ("card");
                content_textview.get_style_context ().add_class ("font-weight-500");

                detail_revealer.reveal_child = true;
                content_label_revealer.reveal_child = false;
                content_textview_revealer.reveal_child = true;
                actionbar_revealer.reveal_child = true;

                content_textview.grab_focus ();
            } else {
                handle_grid.get_style_context ().remove_class ("card");
                content_textview.get_style_context ().remove_class ("font-weight-500");

                detail_revealer.reveal_child = false;
                content_label_revealer.reveal_child = true;
                content_textview_revealer.reveal_child = false;
                actionbar_revealer.reveal_child = false;
            }

            _edit = value;
        }
        get {
            return _edit;
        }
    }

    public bool is_creating {
        get {
            return item.id == Constants.INACTIVE;
        }
    }

    public uint destroy_timeout_id { get; set; default = 0; }

    private const Gtk.TargetEntry[] MAGICBUTTON_TARGET_ENTRIES = {
        {"MAGICBUTTON", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] ITEMROW_TARGET_ENTRIES = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public ItemRow (Objects.Item item) {
        Object (
            item: item,
            can_focus: false
        );
    }

    public ItemRow.for_project (Objects.Project project) {
        var item = new Objects.Item ();
        item.project_id = project.id;

        Object (
            item: item,
            can_focus: false
        );
    }

    public ItemRow.for_section (Objects.Section section) {
        var item = new Objects.Item ();
        item.section_id = section.id;
        item.project_id = section.project.id;

        Object (
            item: item,
            can_focus: false
        );
    }

    construct {
        get_style_context ().add_class ("row");

        build_content ();

        item_summary = new Widgets.ItemSummary (item) {
            margin_start = 21
        };

        description_textview = new Widgets.HyperTextView (_("Description")) {
            height_request = 48,
            left_margin = 21,
            right_margin = 6,
            top_margin = 3,
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            hexpand = true
        };

        description_textview.get_style_context ().remove_class ("view");
        description_textview.get_style_context ().add_class ("dim-label");

        project_button = new Widgets.ProjectButton (item);

        var details_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        details_grid.add (description_textview);
        // details_grid.add (actionbar_revealer);

        detail_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };

        detail_revealer.add (details_grid);

        handle_grid = new Gtk.Grid () {
            margin = 3,
            border_width = 3,
            orientation = Gtk.Orientation.VERTICAL
        };
        handle_grid.get_style_context ().add_class ("transition");
        handle_grid.add (content_top_box);
        handle_grid.add (item_summary);
        handle_grid.add (detail_revealer);

        itemrow_eventbox = new Gtk.EventBox ();
        itemrow_eventbox.add_events (
            Gdk.EventMask.BUTTON_PRESS_MASK |
            Gdk.EventMask.BUTTON_RELEASE_MASK
        );
        itemrow_eventbox.add (handle_grid);

        var top_motion_grid = new Gtk.Grid () {
            margin_top = 6,
            height_request = 16
        };
        top_motion_grid.get_style_context ().add_class ("grid-motion");

        top_motion_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
        };
        top_motion_revealer.add (top_motion_grid);

        var bottom_motion_grid = new Gtk.Grid ();
        bottom_motion_grid.get_style_context ().add_class ("grid-motion");
        bottom_motion_grid.height_request = 16;

        bottom_motion_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        bottom_motion_revealer.add (bottom_motion_grid);

        submit_button = new Widgets.LoadingButton (_("Add Task")) {
            sensitive = false
        };
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        submit_button.get_style_context ().add_class ("small-label");
        submit_button.get_style_context ().add_class ("border-radius-6");

        cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("small-label");
        cancel_button.get_style_context ().add_class ("border-radius-6");
        cancel_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        
        var submit_cancel_grid = new Gtk.Grid () {
            column_spacing = 6
        };
        submit_cancel_grid.add (cancel_button);
        submit_cancel_grid.add (submit_button);

        submit_cancel_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            reveal_child = is_creating
        };

        submit_cancel_revealer.add (submit_cancel_grid);

        var actionbar_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin = 3
        };

        actionbar_box.pack_start (submit_cancel_revealer, false, false, 0);
        actionbar_box.pack_end (project_button, false, false, 0);

        actionbar_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };

        actionbar_revealer.add (actionbar_box);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };
        main_grid.add (top_motion_revealer);
        main_grid.add (itemrow_eventbox);
        main_grid.add (actionbar_revealer);
        main_grid.add (bottom_motion_revealer);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.add (main_grid);

        add (main_revealer);

        update_request ();

        build_drag_and_drop ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            if (is_creating) {
                edit = true;
            }
            return GLib.Source.REMOVE;
        });

        connect_signals ();
    }

    private void build_content () {
        checked_button = new Gtk.CheckButton () {
            can_focus = false,
            valign = Gtk.Align.START
        };

        content_label = new Gtk.Label (null) {
            hexpand = true,
            valign = Gtk.Align.START,
            xalign = 0,
            wrap = false,
            ellipsize = Pango.EllipsizeMode.END,
            use_markup = true
        };

        content_label_revealer = new Gtk.Revealer () {
            valign = Gtk.Align.START,
            transition_type = Gtk.RevealerTransitionType.NONE,
            transition_duration = 125,
            reveal_child = true
        };

        content_label_revealer.add (content_label);

        content_textview = new Widgets.HyperTextView (_("Task Name")) {
            hexpand = true,
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            accepts_tab = false
        };

        content_textview.get_style_context ().remove_class ("view");

        content_textview_revealer = new Gtk.Revealer () {
            valign = Gtk.Align.START,
            transition_type = Gtk.RevealerTransitionType.NONE,
            transition_duration = 125,
        };

        content_textview_revealer.add (content_textview);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.hexpand = true;
        content_box.add (content_label_revealer);
        content_box.add (content_textview_revealer);

        content_top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        content_top_box.pack_start (checked_button, false, false, 0);
        content_top_box.pack_start (content_box, false, true, 6);
    }

    private void connect_signals () {
        itemrow_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                Timeout.add (Constants.DRAG_TIMEOUT, () => {
                    if (main_revealer.reveal_child) {
                        Planner.event_bus.item_selected (item.id);
                    }
                    return GLib.Source.REMOVE;
                });
            } else if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                activate_menu ();
            }

            return Gdk.EVENT_PROPAGATE;
        });

        Planner.event_bus.item_selected.connect ((id) => {
            if (item.id == id) {
                if (edit == false) {
                    edit = true;
                }
            } else {
                edit = false;
            }
        });

        content_textview.key_press_event.connect ((key) => {
            if (Gdk.keyval_name (key.keyval) == "Return") {
                if (is_creating) {
                    add_item ();
                } else {
                    edit = false;
                }
                
                return Gdk.EVENT_STOP;
            }

            return false;
        });

        content_textview.focus_out_event.connect (() => {
            if (is_creating) {
                // destroy_timeout_id = Timeout.add (Constants.DESTROY_TIMEOUT, () => {
                //     hide_destroy ();
                //     return GLib.Source.REMOVE;
                // });
            }

            return false;
        });

        content_textview.focus_in_event.connect (() => {
            if (is_creating) {
                if (destroy_timeout_id != 0) {
                    Source.remove (destroy_timeout_id);
                }
            }
        
            return false;
        });

        description_textview.focus_in_event.connect (() => {
            if (is_creating) {
                if (destroy_timeout_id != 0) {
                    Source.remove (destroy_timeout_id);
                }
            }
        
            return false;
        });

        submit_button.clicked.connect (add_item);

        cancel_button.clicked.connect (() => {
            if (is_creating) {
                Planner.event_bus.item_selected (null);
                hide_destroy ();
            }
        });

        content_textview.buffer.changed.connect (() => {
            submit_button.sensitive = content_textview.is_valid;
        });

        content_textview.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                Planner.event_bus.item_selected (null);
            }

            return false;
        });

        description_textview.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                Planner.event_bus.item_selected (null);
            }

            return false;
        });

        checked_button.button_release_event.connect (() => {
            checked_button.active = !checked_button.active;
            checked_toggled (checked_button.active);
            return Gdk.EVENT_STOP;
        });
    }

    private void add_item () {
        if (content_textview.is_valid) {
            submit_button.is_loading = true;

            item.content = content_textview.get_text ();
            item.description = description_textview.get_text ();

            if (item.project.todoist) {
                Planner.todoist.add_item.begin (item, (obj, res) => {
                    item.id = Planner.todoist.add_item.end (res);
                    add_item_if_not_exists ();
                });
            } else {
                item.id = Util.get_default ().generate_id ();
                add_item_if_not_exists ();
            }
        }
    }

    private void add_item_if_not_exists () {
        if (item.section != null) {
            item.section.add_item_if_not_exists (item, false);
        } else {
            item.project.add_item_if_not_exists (item, false);
        }

        update_request ();
        submit_cancel_revealer.reveal_child = false;
        submit_button.is_loading = false;
        edit = false;
    }

    public void update_request () {
        checked_button.active = item.completed;

        content_label.label = item.content;
        content_textview.set_text (item.content);
        description_textview.set_text (item.description);

        item_summary.update_request ();
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }

    private void build_drag_and_drop () {
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, ITEMROW_TARGET_ENTRIES, Gdk.DragAction.MOVE);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);

        Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, MAGICBUTTON_TARGET_ENTRIES, Gdk.DragAction.MOVE);
        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);
        drag_data_received.connect (on_drag_data_received);
        drag_end.connect (clear_indicator);
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = ((Layouts.ItemRow) widget).handle_grid;

        Gtk.Allocation row_alloc;
        row.get_allocation (out row_alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, row_alloc.width, row_alloc.height);
        var cairo_context = new Cairo.Context (surface);

        var style_context = row.get_style_context ();
        style_context.add_class ("drag-begin");
        row.draw_to_cairo_context (cairo_context);
        style_context.remove_class ("drag-begin");

        int drag_icon_x, drag_icon_y;
        widget.translate_coordinates (row, 0, 0, out drag_icon_x, out drag_icon_y);
        surface.set_device_offset (-drag_icon_x, -drag_icon_y);

        Gtk.drag_set_icon_surface (context, surface);
        main_revealer.reveal_child = false;
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (Layouts.ItemRow))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("ITEMROW"), 32, data
        );
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {

        var target_row = this;
        Gtk.Allocation alloc;
        target_row.get_allocation (out alloc);

        if (target_row == null) {
            return;
        }

        var target_list = (Gtk.ListBox) target_row.parent;
        var position = target_row.get_index () + 1;

        if (target_row.get_index () == 0) {
            if (y > (alloc.height / 2)) {
                position = 0;
            }
        }

        Layouts.ItemRow row;
        if (item.section == null) {
            row = new Layouts.ItemRow.for_project (item.project);
        } else {
            row = new Layouts.ItemRow.for_section (item.section);
        }

        target_list.insert (row, target_row.get_index () + 1);
        target_list.show_all ();
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        Gtk.Allocation alloc;
        itemrow_eventbox.get_allocation (out alloc);
        
        if (get_index () == 0) {
            if (y > (alloc.height / 2)) {
                bottom_motion_revealer.reveal_child = true;
                top_motion_revealer.reveal_child = false;
            } else {
                bottom_motion_revealer.reveal_child = false;
                top_motion_revealer.reveal_child = true;
            }
        } else {
            bottom_motion_revealer.reveal_child = true;
        }

        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        bottom_motion_revealer.reveal_child = false;
        top_motion_revealer.reveal_child = false;
    }

    public void clear_indicator (Gdk.DragContext context) {
        main_revealer.reveal_child = true;
    }

    private void activate_menu () {
        var menu = new Dialogs.ContextMenu.Menu ();
        menu.show_all ();
    }

    private void checked_toggled (bool active) {
        checked_button.active = false;
        if (active) {
            if (item.due_is_recurring == Constants.ACTIVE) {
                // if (item.due_lang == "en") {
                //     GLib.DateTime next_due = Services.Chrono.Chrono.instance.get_next_recurring (item, +1).datetime;
                //     Planner.database.update_item_recurring_due_date (item, +1);
                //     Planner.notifications.send_undo_notification (
                //         _("Completed. Next occurrence: %s".printf (Planner.utils.get_default_date_format_from_date (next_due))),
                //         Planner.utils.build_undo_object ("item_reschedule", "item", item.id.to_string (), "", "")
                //     );
                // } else {
                //     Planner.notifications.send_notification (
                //         _("Sorry, Planner doesn't support the '%s' language yet, please try to set a recurring task in English.".printf (item.due_lang)),
                //         NotificationStyle.ERROR
                //     );
                // }
            } else {
                bool old_checked = item.checked;

                item.checked = true;
                item.completed_at = new GLib.DateTime.now_local ().to_string ();

                Planner.database.checked_toggled (item, old_checked);
                // if (item.is_todoist == 1) {
                //     Planner.todoist.item_complete (item);
                // }
                // main_revealer.reveal_child = false;
                // Planner.notifications.send_undo_notification (
                //     _("1 task completed"),
                //     Planner.utils.build_undo_object ("item_complete", "item", item.id.to_string (), "", "")
                // );
            }
        } else {
            bool old_checked = item.checked;

            item.checked = false;
            item.completed_at = "";

            Planner.database.checked_toggled (item, old_checked);
        }
    }
}
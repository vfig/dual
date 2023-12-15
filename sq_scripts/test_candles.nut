// We're not drawing a HUD, but we're using the HUD api to get screen positions
// and to determine if the object in question is onscreen or not!

enum eCandleState {
    kFocused = 0x01,    // candle was in view on last update.
    kChanged = 0x02,    // candle focused state changed on last update.
    kInvalid = 0x10,    // either disabled, or the object id is no longer valid.
}

class CandlesOverlay extends IDarkOverlayHandler
{
    debug_draw_rects = true;

    // The CandlesController.
    m_controller = 0;

    // Targets: a dict of (objid -> eCandleState).
    m_targets = {};

    // keep these intrefs around so we dont allocate them every frame.
    rx1 = int_ref();
    ry1 = int_ref();
    rx2 = int_ref();
    ry2 = int_ref();

    function Init(controller) {
        m_controller = controller;
    }

    function EnableTarget(target, enable) {
        if (target in m_targets) {
            local state = m_targets[target];
            state = state  & ~eCandleState.kInvalid;
            m_targets[target] = state;
        } else {
            m_targets[target] <- 0;
        }
    }

    function ClearChanged() {
        foreach (target, state in m_targets) {
            state = state & ~eCandleState.kChanged;
            m_targets[target] = state;
        }
    }

    function DrawHUD() {
        // TODO: will need this later to make the 'in view' decision resolution-independent.
        // Engine.GetCanvasSize(rx1, ry1);
        // local screenWidth = rx1.tofloat();
        // local screenHeight = ry1.tofloat();

        // Hardcode a rect that covers the bulk of the periapt in its animation.
        // TODO: This is not a good approach to "was this rendered in the periapt"?
        //       firstly because its not resolution-independent yet. secondly
        //       because its not aspect-ratio independent (where does the periapt
        //       show  up in 4:3? in 21:9? who knows?). thirdly because it is just
        //       a rect that doesnt fully align ever with the periapt. but for now
        //       it is enough to test the rest of the thing with.
        const rect_x1 = 1143;
        const rect_x2 = 1655;
        const rect_y1 = 421;
        const rect_y2 = 824;
        if (debug_draw_rects) {
            DarkOverlay.SetTextColor(64, 0, 64);
            DarkOverlay.DrawLine(rect_x1, rect_y1, rect_x2, rect_y1);
            DarkOverlay.DrawLine(rect_x2, rect_y1, rect_x2, rect_y2);
            DarkOverlay.DrawLine(rect_x1, rect_y1, rect_x1, rect_y2);
            DarkOverlay.DrawLine(rect_x1, rect_y2, rect_x2, rect_y2);

        }

        local any_changed = false;
        foreach (target, state in m_targets) {
            if (state & eCandleState.kInvalid) {
                continue;
            }
            if (! Object.Exists(target)) {
                m_targets[target] = eCandleState.kInvalid;
                continue;
            }
            local visible = DarkOverlay.GetObjectScreenBounds(target, rx1, ry1, rx2, ry2);
            local was_focused = (state & eCandleState.kFocused)!=0;
            local is_focused = false;
            if (visible && !was_focused) {
                local x1 = rx1.tointeger();
                local y1 = ry1.tointeger();
                local x2 = rx2.tointeger();
                local y2 = ry2.tointeger();
                local in_rect = (x1>=rect_x1 && x2<rect_x2 && y1>=rect_y1 && y2<rect_y2);
                if (in_rect) {
                    is_focused = true;
                }
                if (debug_draw_rects) {
                    DarkOverlay.SetTextColor(255, 0, 255);
                    DarkOverlay.DrawLine(x1, y1, x2, y1);
                    DarkOverlay.DrawLine(x2, y1, x2, y2);
                    DarkOverlay.DrawLine(x1, y1, x1, y2);
                    DarkOverlay.DrawLine(x1, y2, x2, y2);
                }
            }

            if (state & eCandleState.kFocused) {
                if (state & eCandleState.kChanged) {
                    // If it was focused in at least one frame between controller updates,
                    // we leave it that way so the focusing doesn't get skipped.
                    continue;
                }
            }

            state = (is_focused? eCandleState.kFocused : 0);
            if (is_focused!=was_focused) {
                state = state|eCandleState.kChanged;
                any_changed = true;
            }
            m_targets[target] = state;
        }

        if (m_controller && any_changed) {
            print("CandlesOverlay: queue update");
            Property.Set(m_controller, "StTweqBlink", "AnimS", TWEQ_AS_ONOFF);
        }
    }

    // TODO: handle resolution changes and such.
    // handler called by the engine when dark initializes UI components,
    // this is also called when resuming game after in-game menu and other
    // UI screens and is a good place to update positioning of HUD elements
    // in case display resolution changed.
    //function OnUIEnterMode() {}
}

g_candles_overlay <- CandlesOverlay();

class CandlesController extends SqRootScript
{
    function destructor() {
        // to be on the safe side make really sure the handler is removed
        // when this script is destroyed (calling RemoveHandler if it's already
        // been removed is no problem)
        DarkOverlay.RemoveHandler(g_candles_overlay);
    }

    function OnBeginScript() {
        g_candles_overlay.Init(self);
        DarkOverlay.AddHandler(g_candles_overlay);
    }

    function OnEndScript() {
        DarkOverlay.RemoveHandler(g_candles_overlay);
    }

    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeFlicker) {
            print("CandlesController: update");
            foreach (target, state in g_candles_overlay.m_targets) {
                // TODO: do something about the target.
            }
            g_candles_overlay.ClearChanged();
            Property.Set(self, "StTweqBlink", "AnimS", 0);
        }
    }
}

class ActiveCandle extends SqRootScript {
    function OnBeginScript() {
        g_candles_overlay.EnableTarget(self, true);
    }

    function OnEndScript() {
        g_candles_overlay.EnableTarget(self, false);
    }

    // TODO: do something with this
            // // We were drawn.
            // DarkUI.TextMessage("OnScreen", 0x0080FF, 100);
}

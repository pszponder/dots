-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- -- https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
-- hl.config({
--   dwindle = {
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
hl.config({
  scrolling = {
    -- Make each column occupy half the screen, without showing the next one at the edge.
    column_width = 0.50,
  },
})

-- https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
-- Only available if using the hyprland-workspace-layout-toggle script.
hl.config({
  master = {
    -- Give the master and slave areas equal width.
    mfact = 0.50,
    -- Keep the focused/new windows in the slave stack by default.
    new_status = "slave",
    -- Put the master area on the left, with slave windows stacked on the right.
    orientation = "left",
  },
})

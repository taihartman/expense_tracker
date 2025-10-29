# Example: Correct Claude Code Workflow

This shows what I (Claude Code) SHOULD HAVE DONE during today's session implementing trip archiving.

## What Actually Happened ❌

```
1. ✅ Plan the features
2. ✅ Implement auto-focus
3. ✅ Add isArchived to Trip model
4. ✅ Update Firestore serialization
5. ✅ Add archive/unarchive methods
6. ✅ Update loadTrips filtering
7. ✅ Create ArchivedTripsPage
8. ✅ Add routes
9. ✅ Update UI components
10. ✅ Add localization strings
11. ✅ Test implementation
12. ❌ Wait for user to remind me about docs
13. ❌ Batch all documentation at the end
```

## What SHOULD Have Happened ✅

```
1. ✅ Plan the features

2. ✅ Implement auto-focus in TripCubit
   → IMMEDIATELY: /docs.log "Added auto-focus: newly created trips are now automatically selected"

3. ✅ Add isArchived to Trip model
   → IMMEDIATELY: /docs.update (architectural change - modified domain model)
   → IMMEDIATELY: /docs.log "Added isArchived field to Trip domain model"

4. ✅ Update Firestore serialization
   → IMMEDIATELY: /docs.log "Updated Trip Firestore model with backward-compatible isArchived serialization"

5. ✅ Add archive/unarchive methods to TripCubit
   → IMMEDIATELY: /docs.update (architectural change - new state management methods)
   → IMMEDIATELY: /docs.log "Added archiveTrip and unarchiveTrip methods to TripCubit"

6. ✅ Update loadTrips filtering
   → IMMEDIATELY: /docs.log "Updated loadTrips to filter and emit separate active/archived trip lists"

7. ✅ Create ArchivedTripsPage
   → IMMEDIATELY: /docs.update (architectural change - new major component)
   → IMMEDIATELY: /docs.log "Created ArchivedTripsPage for managing archived trips"

8. ✅ Add routes
   → IMMEDIATELY: /docs.update (architectural change - routing structure)
   → IMMEDIATELY: /docs.log "Added /trips/archived route"

9. ✅ Update UI components
   → IMMEDIATELY: /docs.log "Added archive section to Trip Settings and View Archived button to Trip List"

10. ✅ Add localization strings
    → IMMEDIATELY: /docs.log "Added 10 new localization strings for archive functionality"

11. ✅ Test implementation
    → IMMEDIATELY: /docs.log "Verified all changes with flutter analyze - no errors"

12. ✅ Mark feature complete
    → /docs.update (final architecture sync)
    → /docs.complete (roll up to root CHANGELOG)
```

## Key Differences

### ❌ BAD (What I Did):
- Waited until the end
- User had to remind me
- Batched all documentation
- Lost context about individual changes

### ✅ GOOD (What I Should Do):
- Document as I go
- Proactive, not reactive
- Use `/docs.update` after each architectural change
- Use `/docs.log` after each significant change
- Never wait for user to remind me

## Triggers for `/docs.update`

In this session, I should have called `/docs.update` after:
1. Adding `isArchived` field to Trip model ← Domain model change
2. Adding archive methods to TripCubit ← State management change
3. Creating ArchivedTripsPage ← New major component
4. Adding `/trips/archived` route ← Routing change

**Total `/docs.update` calls I should have made: 4**
**Total `/docs.update` calls I actually made: 0 (user had to ask)**

## Remember

Documentation is NOT a separate step - it's part of development!

Every todo completion should be followed by documentation.

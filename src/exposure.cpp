#include <Rcpp.h>
#include <map>
using namespace Rcpp;

// This classes assume there are no duplicates at the level (person, event),
// and data is properly sorted by (time, event)

class PersonDyn;

class Event {
public:
  std::vector< int > records;
  Event() {};
};

#define NOT_COUNTED 0
#define I_COUNTED 1
#define D_COUNTED 2
#define ID_COUNTED 3

class PersonDyn {

public:

  // List of past colleagues
  int id;
  std::vector< int > event_loc;
  std::vector<Event*> events;
  std::map<int, std::pair<int, PersonDyn*>> colleagues;

  // Dynamic (rolling) variables
  bool ever_used = false;

  PersonDyn(int id_, int loc, Event* e) : id(id_), event_loc({loc}), events({e}) {};
  void add_event(int loc, Event* e);

  PersonDyn();

};


inline PersonDyn::PersonDyn() {};

inline void PersonDyn::add_event(int loc, Event* e)
{
  event_loc.push_back(loc);
  events.push_back(e);
}

// Data must be sorted by individual
// [[Rcpp::export(rng = false, name = "exposure_dyn_")]]
List exposure(
  const IntegerVector & id_indiv,
  const IntegerVector & id_events,
  const IntegerVector & actions,
  int offset = 1
) {

  if (offset < 0)
    stop("No support for -offset- < 0");

  int N = id_indiv.size();
  IntegerVector ans(N);
  std::map<int,Event> events;
  std::map<int,PersonDyn> persons;

  // Step 1: Listing events x individuals --------------------------------------
  int i = 0;
  while (i < N)
  {

    // Keeping the event id.
    int tmp_event_id = id_events[i];

    // Does not exists, so we start moving ahead
    if (events.find(tmp_event_id) == events.end())
      events[tmp_event_id] = Event();

    Event * event_ptr = &events[tmp_event_id];

    // Checking the person
    int tmp_person_id = id_indiv[i];
    if (persons.find(tmp_person_id) == persons.end())
      persons[tmp_person_id] = PersonDyn(tmp_person_id, i, event_ptr);
    else
      persons[tmp_person_id].add_event(i, event_ptr);

    // Adding the person to the event
    event_ptr->records.push_back(i);

    // Next iteration
    i++;

  }

  // Step 2: We now compute cumulative usage -----------------------------------
  IntegerVector cumuse = clone(actions);
  for (auto & p_iter : persons)
  {
    const PersonDyn & p = p_iter.second;

    // If it happens to be a single event, then continue to the next
    if (p.event_loc.size() == 1u)
      continue;

    // Otherwise, the individual has many more events
    // ycum(t) = y(t) + ycum(t-1)
    for (int i = 1; i < p.events.size(); ++i)
      cumuse[p.event_loc[i]] += cumuse[p.event_loc[i-1]];

  }

  // Step 3: Computing exposures -----------------------------------------------
  IntegerVector exposure_i(N, 0);
  IntegerVector exposure_d(N, 0);
  IntegerVector exposure_i_cum(N, NA_INTEGER);
  IntegerVector exposure_d_cum(N, NA_INTEGER);

  for (auto & p_iter : persons)
  {
    // Saving space
    PersonDyn & p = p_iter.second;
    int event_num = 0u;

    // Temp exposures
    IntegerVector exp_i_tmp(p.event_loc.size(), 0);
    IntegerVector exp_d_tmp(p.event_loc.size(), 0);

    // Iterating through the persons' events
    for (auto & e_ptr: p.events)
    {

      // Checking peers
      for (auto & r : e_ptr->records)
      {

        int peer_id = id_indiv[r];

        // Is it self?
        if (peer_id == p.id)
          continue;

        // Otherwise, check if it is registered.
        // If it is not present, then we need to add it to the list.
        // In such case, if the individual actually pointed
        if (p.colleagues.find(peer_id) == p.colleagues.end())
        {

          // Since this is the first time it sees the neighbor, and they
          // may have an action, it is added to the direct exposure.
          if (actions[r] > 0)
            ++exp_d_tmp[event_num];

          if (cumuse[r] > 0)
            ++exp_i_tmp[event_num];

          if ((actions[r] > 0) & (cumuse[r] > 0))
          {

            // Adding to the list
            p.colleagues[peer_id] = std::pair<int,PersonDyn*>(
              ID_COUNTED,
              &persons[peer_id]
            );

          } else if ((actions[r] == 0) & (cumuse[r] > 0))
          {

            // Adding to the list
            p.colleagues[peer_id] = std::pair<int,PersonDyn*>(
              I_COUNTED,
              &persons[peer_id]
            );

          } else if ((actions[r] > 0) & (cumuse[r] == 0))
          {

            // Adding to the list
            p.colleagues[peer_id] = std::pair<int,PersonDyn*>(
              D_COUNTED,
              &persons[peer_id]
            );

          } else {

            // Adding to the list
            p.colleagues[peer_id] = std::pair<int,PersonDyn*>(
              NOT_COUNTED,
              &persons[peer_id]
            );

          }

        } else { // Need to check whether the individual has or hasnt

          std::pair<int,PersonDyn*> * colleague = &p.colleagues[peer_id];

          // Already counted
          if (colleague->first == ID_COUNTED)
            continue;

          // Haven't count direct (but now there is)
          else if ((colleague->first == I_COUNTED) && (actions[r] > 0)) {
            colleague->first = ID_COUNTED;
            ++exp_d_tmp[event_num];
          }
          // Haven't count indirect (but now there is)
          else if ((colleague->first == D_COUNTED) && (cumuse[r] > 0)) {
            colleague->first = ID_COUNTED;
            ++exp_i_tmp[event_num];
          }
          else if (colleague->first == NOT_COUNTED) {

            // Both are
            if ((actions[r] > 0) & (cumuse[r] > 0)) {
              colleague->first = ID_COUNTED;
              ++exp_i_tmp[event_num];
              ++exp_d_tmp[event_num];
              // Only indirect
            } else if ((actions[r] == 0) & (cumuse[r] > 0)) {
              colleague->first = I_COUNTED;
              ++exp_i_tmp[event_num];
              // Only direct
            } else if ((actions[r] > 0) & (cumuse[r] == 0)) {
              colleague->first = D_COUNTED;
              ++exp_d_tmp[event_num];
            }

          }


        }

      }

      // Once all peers checked, we go to the next event
      if ((++event_num) >= p.event_loc.size())
        break;

    }

    // Once we are done computing the exposures, we can apply the offset as needed
    for (int i = offset; i < p.event_loc.size(); ++i)
    {
      exposure_i[p.event_loc[i]] = exp_i_tmp[i - offset];
      exposure_d[p.event_loc[i]] = exp_d_tmp[i - offset];
      exposure_i_cum[p.event_loc[i]] = exp_i_tmp[i - offset];
      exposure_d_cum[p.event_loc[i]] = exp_d_tmp[i - offset];

      if (i > offset) {
        exposure_i_cum[p.event_loc[i]] +=
          exposure_i_cum[p.event_loc[i - 1]];

        exposure_d_cum[p.event_loc[i]] +=
          exposure_d_cum[p.event_loc[i - 1]];
      }

    }

  }

  return List::create(
    _["cumsum"]         = cumuse,
    _["exposure_i"]     = exposure_i,
    _["exposure_d"]     = exposure_d,
    _["exposure_i_cum"] = exposure_i_cum,
    _["exposure_d_cum"] = exposure_d_cum
  );

}

#undef NOT_COUNTED
#undef I_COUNTED
#undef D_COUNTED
#undef ID_COUNTED

/* **R
library(data.table)

# Generating the data
set.seed(1231)
n <- 100000
dat <- data.table(
  fired = sample.int(2, n, replace = TRUE, prob = c(.8, .2)) - 1,
  id    = sample.int(floor(n/10), n, replace=TRUE),
  event = sample.int(n/5, n, replace=TRUE)
)

# Keeping one observation of individual per record
dat[, n := 1:.N, by = .(event, id)]
dat <- dat[n == 1]
dat[, n := NULL]
setorder(dat, event, id)

ans1 <- with(dat, as.data.frame(exposure(
  id_indiv  = id,
  id_events = event,
  actions   = fired, offset = 1
)))

ans2 <- with(dat, as.data.frame(exposure(
  id_indiv  = id,
  id_events = event,
  actions   = fired, offset = 00
)))


ans <- data.table(
  id    = dat$id,
  event = dat$event,
  exp_i1 = ans1$exposure_i,
  exp_i2 = ans2$exposure_i,
  exp_d1 = ans1$exposure_d,
  exp_d2 = ans2$exposure_d,
  exp_i_cum1 = ans1$exposure_i_cum,
  exp_i_cum2 = ans2$exposure_i_cum,
  exp_d_cum1 = ans1$exposure_d_cum,
  exp_d_cum2 = ans2$exposure_d_cum
)

ans[, exp_i1b := shift(exp_i1, n = 1, type = "lead", fill = NA_integer_), by = .(id)]
ans[, table(exp_i2 == exp_i1b, useNA = "always")]
ans[exp_i2 != exp_i1b] |> View()

cbind(dat, ans) |> View()

# Looking at the individual with most records
most_pop <- dat[, .(N = .N), by = id][order(-N)][1]$id

cbind(dat, ans)[id == most_pop] |> View()
ans[exposure_d_cum != exposure_d]

# Test 2: Offset matches by individual

# Test 1: Avoids double counting -----------------------------------------------
dat <- data.table(
  event = c(1,1,1, 2,2,2, 3,3,3,3, 4,4,4,4),
  id    = c(1,2,3, 1,2,4, 2,3,4,5, 5,1,6,2),
  fired = c(1,1,1, 0,1,1, 0,1,0,1, 1,0,1,1)
)

ans <- with(dat, as.data.frame(exposure(
  id_indiv  = id,
  id_events = event,
  actions   = fired,
  offset    = 0
)))

ans <- as.data.table(ans)
cbind(dat, ans)
*/
